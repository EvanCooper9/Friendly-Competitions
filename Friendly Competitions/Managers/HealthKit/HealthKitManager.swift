import Algorithms
import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import HealthKit

// sourcery: AutoMockable
protocol HealthKitManaging {
    func execute(_ query: AnyHealthKitQuery)
    func registerBackgroundDeliveryTask(_ publisher: AnyPublisher<Void, Never>, for permission: HealthKitPermissionType)
    func registerForBackgroundDelivery()

    func shouldRequest(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error>
    func request(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Void, Error>
}

final class HealthKitManager: HealthKitManaging {

    // MARK: - Private Properties

    @Injected(\.analyticsManager) private var analyticsManager: AnalyticsManaging
    @Injected(\.authenticationManager) private var authenticationManager: AuthenticationManaging
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging
    @Injected(\.healthStore) private var healthStore: HealthStoring
    @Injected(\.scheduler) private var scheduler: AnySchedulerOf<RunLoop>

    private var backgroundDeliveryPublishers = [HealthKitPermissionType: [AnyPublisher<Void, Never>]]()
    private var cancellables = Cancellables()

    // MARK: - Public Methods

    func execute(_ query: AnyHealthKitQuery) {
        healthStore.execute(query)
    }

    func registerBackgroundDeliveryTask(_ publisher: AnyPublisher<Void, Never>, for permission: HealthKitPermissionType) {
        let publishers = backgroundDeliveryPublishers[permission] ?? []
        backgroundDeliveryPublishers[permission] = publishers.appending(publisher)
        registerPermissionsForBackgroundDelivery([permission])
    }

    func shouldRequest(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error> {
        healthStore
            .shouldRequest(permissions)
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf, shouldRequest in
                let permissionsString = permissions.map(\.rawValue).joined(separator: "_")
                strongSelf.analyticsManager.log(event: .healthKitShouldRequestPermissions(permissionsString: permissionsString, shouldRequest: shouldRequest))
            })
            .eraseToAnyPublisher()
    }

    func request(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Void, Error> {
        healthStore.request(permissions)
            .handleEvents(withUnretained: self, receiveOutput: { $0.registerPermissionsForBackgroundDelivery(permissions) })
            .eraseToAnyPublisher()
    }

    func registerForBackgroundDelivery() {
        authenticationManager.loggedIn
            .filter { $0 }
            .mapToVoid()
            .flatMapLatest(withUnretained: self) { strongSelf in
                HealthKitPermissionType.allCases
                    .map { permission in
                        strongSelf
                            .shouldRequest([permission])
                            .catchErrorJustReturn(false)
                            .map { (permission: permission, shouldRequest: $0) }
                    }
                    .combineLatest()
                    .filterMany { !$0.shouldRequest }
                    .mapMany { $0.permission }
            }
            .sink(withUnretained: self) { strongSelf, permissions in
                strongSelf.registerPermissionsForBackgroundDelivery(permissions)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func registerPermissionsForBackgroundDelivery(_ permissions: [HealthKitPermissionType]) {
        for permission in permissions {
            guard let hkSampleType = permission.objectType as? HKSampleType else { continue }
            let query = ObserverQuery(sampleType: hkSampleType) { [weak self] result in
                guard let self else { return }
                analyticsManager.log(event: .healthKitBGDeliveryReceived(permission: permission))
                switch result {
                case .failure(let error):
                    analyticsManager.log(event: .healthKitBGDeliveryError(permission: permission, error: error.localizedDescription))

                    if error.isHealthKitAuthorizationError {
                        backgroundDeliveryPublishers[permission]?.removeAll()
                        healthStore.disableBackgroundDelivery(for: permission)
                            .sink()
                            .store(in: &cancellables)
                    }

                    error.reportToCrashlytics()
                case .success(let backgroundDeliveryCompletion):
                    guard let publishers = backgroundDeliveryPublishers[permission], publishers.isNotEmpty else {
                        analyticsManager.log(event: .healthKitBGDelieveryMissingPublisher(permission: permission))
                        backgroundDeliveryCompletion()
                        return
                    }
                    analyticsManager.log(event: .healthKitBGDeliveryProcessing(permission: permission))

                    let timeout = featureFlagManager.value(forDouble: .healthKitBackgroundDeliveryTimeoutMS)
                    publishers
                        .combineLatest()
                        .mapToVoid()
                        .setFailureType(to: HealthKitBackgroundDeliveryError.self)
                        .timeout(.milliseconds(Int(timeout)), scheduler: scheduler) {
                            HealthKitBackgroundDeliveryError.timeout
                        }
                        .first()
                        .sink(receiveCompletion: { [analyticsManager] completion in
                            switch completion {
                            case .finished:
                                analyticsManager.log(event: .healthKitBGDeliverySuccess(permission: permission))
                            case .failure(let error):
                                switch error {
                                case .timeout:
                                    analyticsManager.log(event: .healthKitBGDeliveryTimeout(permission: permission))
                                }
                            }
                            backgroundDeliveryCompletion()
                        }, receiveValue: {
                            backgroundDeliveryCompletion()
                        })
                        .store(in: &cancellables)
                }
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: permission)
                .sink(withUnretained: self, receiveCompletion: { strongSelf, completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        strongSelf.analyticsManager.log(event: .healthKitRegisterBGDeliveryFailure(permission: permission, error: error.localizedDescription))
                    }
                }, receiveValue: { strongSelf, success in
                    if success {
                        strongSelf.analyticsManager.log(event: .healthKitRegisterBGDeliverySuccess(permission: permission))
                    } else {
                        strongSelf.analyticsManager.log(event: .healthKitRegisterBGDeliveryFailure(permission: permission, error: nil))
                    }
                })
                .store(in: &cancellables)
        }
    }
}

private extension Error {
    var isHealthKitAuthorizationError: Bool {
        let nsError = self as NSError
        return nsError.domain == "com.apple.healthkit" && nsError.code == 5
    }
}
