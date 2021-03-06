import Combine
import HealthKit
import Resolver
import SwiftUI

class AnyHealthKitManager: ObservableObject {
    let backgroundDeliveryReceived = PassthroughSubject<Void, Never>()
    var permissionStatus: PermissionStatus { .authorized }
    func execute(_ query: HKQuery) {}
    func requestPermissions(_ completion: @escaping (PermissionStatus) -> Void) {}
    func registerForBackgroundDelivery() {}
}

final class HealthKitManager: AnyHealthKitManager {

    private enum Constants {
        static var backgroundDeliveryTypes: [HKSampleType] {
            permissionObjectTypes.compactMap { $0 as? HKSampleType }
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

    override var permissionStatus: PermissionStatus { storedPermissionStatus ?? .notDetermined }

    // MARK: - Private Properties
    
    @Injected private var analyticsManager: AnyAnalyticsManager

    private let healthStore = HKHealthStore()
    private var hasRegisteredForBackgroundDelivery = false

    @AppStorage("healthKitStoredPermissionStatus") private var storedPermissionStatus: PermissionStatus?

    private var notDeterminedPermissions: [HKObjectType] {
        Constants.permissionObjectTypes.filter { healthStore.authorizationStatus(for: $0) == .notDetermined }
    }

    private var updateTask: Task<Void, Error>? {
        willSet { updateTask?.cancel() }
    }

    // MARK: - Initializers

    override init() {
        super.init()
        if notDeterminedPermissions.isEmpty { storedPermissionStatus = .done }
    }

    // MARK: - Public Methods

    override func execute(_ query: HKQuery) {
        healthStore.execute(query)
    }

    override func requestPermissions(_ completion: @escaping (PermissionStatus) -> Void) {
        guard storedPermissionStatus == .notDetermined || storedPermissionStatus == nil else {
            completion(permissionStatus)
            return
        }

        healthStore.requestAuthorization(
            toShare: nil,
            read: .init(Constants.permissionObjectTypes),
            completion: { [weak self] authorized, error in
                guard let self = self else { return }
                let permissionStatus: PermissionStatus = authorized ? .authorized : .denied
                self.analyticsManager.log(event: .notificationPermissions(authorized: authorized))
                DispatchQueue.main.async {
                    self.storedPermissionStatus = permissionStatus
                    self.registerForBackgroundDelivery()
                }
                completion(permissionStatus)
            }
        )
    }

    override func registerForBackgroundDelivery() {
        guard storedPermissionStatus == .authorized || storedPermissionStatus == .done else { return }
        guard !hasRegisteredForBackgroundDelivery else {
            backgroundDeliveryReceived.send()
            return
        }

        for sampleType in Constants.backgroundDeliveryTypes {
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] query, completion, error in
                guard let self = self else { return }
                self.backgroundDeliveryReceived.send()
                completion()
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { _, _ in }
        }
        hasRegisteredForBackgroundDelivery.toggle()
    }
}
