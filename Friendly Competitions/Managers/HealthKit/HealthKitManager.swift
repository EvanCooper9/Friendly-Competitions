import Combine
import Factory
import HealthKit

// sourcery: AutoMockable
protocol HealthKitManaging {
    var backgroundDeliveryReceived: AnyPublisher<Void, Never> { get }
    var permissionStatus: AnyPublisher<PermissionStatus, Never> { get }
    func execute(_ query: HKQuery)
    func requestPermissions()
}

final class HealthKitManager: HealthKitManaging {

    // MARK: - Public Properties

    var backgroundDeliveryReceived: AnyPublisher<Void, Never> { _backgroundDeliveryReceived.eraseToAnyPublisher() }
    let permissionStatus: AnyPublisher<PermissionStatus, Never>

    // MARK: - Private Properties
    
    @Injected(Container.analyticsManager) private var analyticsManager

    private let healthStore = HKHealthStore()
    private let _backgroundDeliveryReceived = PassthroughSubject<Void, Never>()
    private let _permissionStatus: CurrentValueSubject<[HealthKitPermissionType: PermissionStatus], Never>

    // MARK: - Initializers

    init() {
        _permissionStatus = .init(UserDefaults.standard.decode([HealthKitPermissionType: PermissionStatus].self, forKey: "health_kit_permissions") ?? [:])
        permissionStatus = _permissionStatus
            .handleEvents(receiveOutput: { UserDefaults.standard.encode($0, forKey: "health_kit_permissions") })
            .map { permissionStatuses in
                let hasUndetermined = HealthKitPermissionType.allCases
                    .contains { permissionType in
                        guard let permissionStatus = permissionStatuses[permissionType] else {
                            return true
                        }
                        return permissionStatus == .notDetermined
                    }

                guard !hasUndetermined else { return .notDetermined }

                let authorized = HealthKitPermissionType.allCases.allSatisfy { permissionStatuses[$0] == .authorized }
                return authorized ? .authorized : .denied
            }
            .eraseToAnyPublisher()

        registerForBackgroundDelivery()
    }

    // MARK: - Public Methods

    func execute(_ query: HKQuery) {
        healthStore.execute(query)
    }

    func requestPermissions() {
        let permissionsToRequest = HealthKitPermissionType.allCases
            .filter { _permissionStatus.value[$0] != .authorized }

        healthStore.requestAuthorization(
            toShare: nil,
            read: .init(permissionsToRequest.map(\.objectType)),
            completion: { [weak self] authorized, error in
                guard let strongSelf = self else { return }
                let permissionStatus: PermissionStatus = authorized ? .authorized : .denied
                strongSelf.analyticsManager.log(event: .healthKitPermissions(authorized: authorized))
                var currentPermissions = strongSelf._permissionStatus.value
                permissionsToRequest.forEach { currentPermissions[$0] = permissionStatus }
                strongSelf._permissionStatus.send(currentPermissions)
                strongSelf.registerForBackgroundDelivery()
            }
        )
    }

    // MARK: - Private Methods

    private func registerForBackgroundDelivery() {
        let backgroundDeliveryTypes = HealthKitPermissionType.allCases
            .filter { _permissionStatus.value[$0] == .authorized }
            .compactMap { $0.objectType as? HKSampleType }

        for sampleType in backgroundDeliveryTypes {
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] query, completion, _ in
                guard let self = self else { return }
                self._backgroundDeliveryReceived.send()
                completion()
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: sampleType, frequency: .hourly) { _, _ in }
        }
    }
}
