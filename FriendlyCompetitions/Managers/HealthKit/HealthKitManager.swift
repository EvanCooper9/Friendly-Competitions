import Algorithms
import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import FCKit
import HealthKit

typealias HealthKitBackgroundDeliveryTask = () -> AnyPublisher<Void, Never>

// sourcery: AutoMockable
protocol HealthKitManaging {
    var permissionsChanged: AnyPublisher<Void, Never> { get }

    func execute(_ query: AnyHealthKitQuery)
    func registerBackgroundDeliveryTask(for permission: HealthKitPermissionType, task: @escaping HealthKitBackgroundDeliveryTask)
    func registerBackgroundDeliveryPublisher(for permission: HealthKitPermissionType, publisher: AnyPublisher<Void, Never>)
    func registerForBackgroundDelivery()

    func shouldRequest(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error>
    func request(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Void, Error>
}

final class HealthKitManager: HealthKitManaging {

    let permissionsChanged: AnyPublisher<Void, Never>

    // MARK: - Private Properties

    @Injected(\.analyticsManager) private var analyticsManager: AnalyticsManaging
    @Injected(\.authenticationManager) private var authenticationManager: AuthenticationManaging
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging
    @Injected(\.healthStore) private var healthStore: HealthStoring
    @Injected(\.scheduler) private var scheduler: AnySchedulerOf<RunLoop>

    private var permissionsChangedSubject = PassthroughSubject<Void, Never>()
    private var backgroundDeliveryTasks = [HealthKitPermissionType: [HealthKitBackgroundDeliveryTask]]()
    private var backgroundDeliveryPublishers = [HealthKitPermissionType: [AnyPublisher<Void, Never>]]()
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        permissionsChanged = permissionsChangedSubject.eraseToAnyPublisher()
    }

    // MARK: - Public Methods

    func execute(_ query: AnyHealthKitQuery) {
        healthStore.execute(query)
    }

    func registerBackgroundDeliveryTask(for permission: HealthKitPermissionType, task: @escaping HealthKitBackgroundDeliveryTask) {
        let tasks = backgroundDeliveryTasks[permission] ?? []
        backgroundDeliveryTasks[permission] = tasks.appending(task)
    }

    func registerBackgroundDeliveryPublisher(for permission: HealthKitPermissionType, publisher: AnyPublisher<Void, Never>) {
        let publishers = backgroundDeliveryPublishers[permission] ?? []
        backgroundDeliveryPublishers[permission] = publishers.appending(publisher)
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
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf, success in
                guard success else { return }
                strongSelf.registerPermissionsForBackgroundDelivery(permissions)
                strongSelf.permissionsChangedSubject.send(())
            })
            .mapToVoid()
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
                analyticsManager.log(event: .healthKitBGDeliveryReceived(permission: permission.rawValue))
                switch result {
                case .failure(let error):
                    analyticsManager.log(event: .healthKitBGDeliveryError(permission: permission.rawValue, error: error.localizedDescription))

                    if error.isHealthKitAuthorizationError {
                        backgroundDeliveryTasks[permission]?.removeAll()
                        backgroundDeliveryPublishers[permission]?.removeAll()
                        healthStore.disableBackgroundDelivery(for: permission)
                            .sink()
                            .store(in: &cancellables)
                    }

                    error.reportToCrashlytics()
                case .success(let backgroundDeliveryCompletion):
                    let publishers: [AnyPublisher<Void, Never>]

                    if featureFlagManager.value(forBool: .sharedBackgroundDeliveryPublishers) {
                        publishers = backgroundDeliveryTasks[permission]?.map { $0() } ?? []
                    } else {
                        publishers = backgroundDeliveryPublishers[permission] ?? []
                    }

                    guard publishers.isNotEmpty else {
                        analyticsManager.log(event: .healthKitBGDelieveryMissingPublisher(permission: permission.rawValue))
                        backgroundDeliveryCompletion()
                        return
                    }
                    analyticsManager.log(event: .healthKitBGDeliveryProcessing(permission: permission.rawValue))

                    let timeout = featureFlagManager.value(forDouble: .healthKitBackgroundDeliveryTimeoutMS)
                    publishers
                        .combineLatest()
                        .mapToVoid()
                        .setFailureType(to: HealthKitBackgroundDeliveryError.self)
                        .timeout(.milliseconds(Int(timeout)), scheduler: scheduler) {
                            return HealthKitBackgroundDeliveryError.timeout
                        }
                        .first()
                        .sink(receiveCompletion: { [analyticsManager] completion in
                            defer {
                                backgroundDeliveryCompletion()
                            }
                            switch completion {
                            case .finished:
                                analyticsManager.log(event: .healthKitBGDeliverySuccess(permission: permission.rawValue))
                            case .failure(let error):
                                switch error {
                                case .timeout:
                                    analyticsManager.log(event: .healthKitBGDeliveryTimeout(permission: permission.rawValue))
                                }
                            }
                        }, receiveValue: { _ in
                            // no-op
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
                        strongSelf.analyticsManager.log(event: .healthKitRegisterBGDeliveryFailure(permission: permission.rawValue, error: error.localizedDescription))
                    }
                }, receiveValue: { strongSelf, success in
                    if success {
                        strongSelf.analyticsManager.log(event: .healthKitRegisterBGDeliverySuccess(permission: permission.rawValue))
                    } else {
                        strongSelf.analyticsManager.log(event: .healthKitRegisterBGDeliveryFailure(permission: permission.rawValue, error: nil))
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
