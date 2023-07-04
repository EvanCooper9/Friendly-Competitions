import Algorithms
import Combine
import CombineExt
import ECKit
import Factory
import HealthKit

// sourcery: AutoMockable
protocol HealthKitManaging {
    func execute(_ query: AnyHealthKitQuery)
    func registerBackgroundDeliveryTask(_ publisher: AnyPublisher<Void, Never>)

    func shouldRequest(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error>
    func request(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Void, Error>
}

final class HealthKitManager: HealthKitManaging {

    // MARK: - Private Properties

    @Injected(\.analyticsManager) private var analyticsManager
    @Injected(\.healthStore) private var healthStore

    private let backgroundDeliveryReceivedSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Initializers

    init() {
        HealthKitPermissionType.allCases
            .map { permission -> AnyPublisher<HealthKitPermissionType?, Never> in
                shouldRequest([permission])
                    .catchErrorJustReturn(false)
                    .map { $0 ? nil : permission }
                    .eraseToAnyPublisher()
            }
            .combineLatest()
            .sink(withUnretained: self) { strongSelf, permissions in
                strongSelf.registerPermissionsForBackgroundDelivery(Array(permissions.compacted()))
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func execute(_ query: AnyHealthKitQuery) {
        healthStore.execute(query)
    }

    private var backgroundDeliveryPublishers = [AnyPublisher<Void, Never>]()
    func registerBackgroundDeliveryTask(_ publisher: AnyPublisher<Void, Never>) {
        backgroundDeliveryPublishers.append(publisher)
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

    // MARK: - Private Methods

    private func registerPermissionsForBackgroundDelivery(_ permissions: [HealthKitPermissionType]) {
        for permission in permissions {
            guard let hkSampleType = permission.objectType as? HKSampleType else { continue }
            let query = ObserverQuery(sampleType: hkSampleType) { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case .failure(let error):
                    error.reportToCrashlytics()
                case .success(let completion):
                    strongSelf.backgroundDeliveryPublishers
                        .combineLatest()
                        .mapToVoid()
                        .first()
                        .sink(receiveValue: completion)
                        .store(in: &strongSelf.cancellables)
                }
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: permission)
                .first()
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
