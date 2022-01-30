import HealthKit
import Resolver

protocol HealthKitBackgroundDeliveryReceiving {
    func trigger() async throws
}

class AnyHealthKitManager: ObservableObject {

    var permissionStatus: PermissionStatus { .authorized }

    func execute(_ query: HKQuery) {}

    func requestPermissions(_ completion: @escaping (PermissionStatus) -> Void) {}

    private(set) var didRegisterForBackgroundDelivery = false
    func registerForBackgroundDelivery() {
        didRegisterForBackgroundDelivery = true
    }

    private(set) var didRegisterBackgroundDeliveryReceiver = false
    func registerBackgroundDeliveryReceiver(_ backgroundDeliverReceiver: HealthKitBackgroundDeliveryReceiving) {
        didRegisterBackgroundDeliveryReceiver = true
    }
}

final class HealthKitManager: AnyHealthKitManager {

    private enum Constants {

        static let permissionStoreKey = #function

        static var backgroundDeliveryTypes: [HKSampleType] {
            Self.permissionObjectTypes.compactMap { $0 as? HKSampleType }
        }

        static let permissionObjectTypes: [HKObjectType] = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.appleMoveTime),
            HKQuantityType(.appleStandTime),
            HKCategoryType(.appleStandHour),
            HKQuantityType(.stepCount),
            HKQuantityType(.flightsClimbed),
            .workoutType(),
            .activitySummaryType()
        ]
    }

    // MARK: - Public Properties

    override var permissionStatus: PermissionStatus {
        guard notDeterminedPermissions.isEmpty else { return .notDetermined }
        // https://stackoverflow.com/questions/29076655/healthkit-authorisation-status-is-always-1
        return UserDefaults.standard.decode(PermissionStatus.self, forKey: Constants.permissionStoreKey) ?? .notDetermined
    }

    // MARK: - Private Properties

    private let healthStore = HKHealthStore()
    private var hasRegisteredForBackgroundDelivery = false
    private var backgroundDeliverReceivers = [HealthKitBackgroundDeliveryReceiving]()

    private var notDeterminedPermissions: [HKObjectType] {
        Constants.permissionObjectTypes.filter { healthStore.authorizationStatus(for: $0) == .notDetermined }
    }

    private var updateTask: Task<Void, Error>? {
        willSet { updateTask?.cancel() }
    }

    // MARK: - Public Methods

    override func execute(_ query: HKQuery) {
        healthStore.execute(query)
    }

    override func requestPermissions(_ completion: @escaping (PermissionStatus) -> Void) {
        guard !notDeterminedPermissions.isEmpty else {
            completion(permissionStatus)
            return
        }

        healthStore.requestAuthorization(
            toShare: nil,
            read: .init(Constants.permissionObjectTypes),
            completion: { [weak self] authorized, error in
                guard let self = self else { return }
                self.registerForBackgroundDelivery()
                let permissionStatus: PermissionStatus = authorized ? .authorized : .denied
                UserDefaults.standard.encode(permissionStatus, forKey: Constants.permissionStoreKey)
                completion(permissionStatus)
            }
        )
    }

    override func registerForBackgroundDelivery() {
        guard notDeterminedPermissions.isEmpty else { return }
        guard !hasRegisteredForBackgroundDelivery else {
            for receiver in backgroundDeliverReceivers {
                Task { try await receiver.trigger() }
            }
            return
        }
        for sampleType in Constants.backgroundDeliveryTypes {
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] query, completion, error in
                guard let self = self else { return }
                self.updateTask = Task(priority: .low) {
                    defer { completion() }
                    for receiver in self.backgroundDeliverReceivers {
                        try Task.checkCancellation()
                        try await receiver.trigger()
                    }
                }
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { _, _ in }
        }
        hasRegisteredForBackgroundDelivery.toggle()
    }

    override func registerBackgroundDeliveryReceiver(_ backgroundDeliverReceiver: HealthKitBackgroundDeliveryReceiving) {
        backgroundDeliverReceivers.append(backgroundDeliverReceiver)
    }
}
