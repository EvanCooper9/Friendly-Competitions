import FirebaseAnalytics
import HealthKit
import Resolver
import UIKit
import UserNotifications

protocol HealthKitManaging {
    var shouldRequestPermissions: Bool { get }
    func requestPermissions(_ completion: @escaping ((Bool, Error?) -> Void))
    func registerForBackgroundDelivery()
    func registerBackgroundDeliveryReceiver(_ receiver: HealthKitBackgroundDeliveryReceiving)
}

protocol HealthKitBackgroundDeliveryReceiving {
    func trigger() async throws
}

final class HealthKitManager: HealthKitManaging {

    private enum Constants {

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

    var shouldRequestPermissions: Bool {
        !permissionsNotRequested.isEmpty
    }

    // MARK: - Private Properties

    private let healthStore = HKHealthStore()
    private var handlers = [() async throws -> Void]()
    private var receivers = [HealthKitBackgroundDeliveryReceiving]()

    private var permissionsNotRequested: [HKObjectType] {
        Constants.permissionObjectTypes.filter { healthStore.authorizationStatus(for: $0) == .notDetermined }
    }

    // MARK: - Public Methods

    func requestPermissions(_ completion: @escaping ((Bool, Error?) -> Void)) {
        guard !permissionsNotRequested.isEmpty else {
            completion(true, nil)
            return
        }

        healthStore.requestAuthorization(
            toShare: nil,
            read: .init(Constants.permissionObjectTypes),
            completion: { [weak self] success, error in
                self?.registerForBackgroundDelivery()
                completion(success, error)
            }
        )
    }

    func registerForBackgroundDelivery() {
        guard permissionsNotRequested.isEmpty else { return }
        for type in Constants.backgroundDeliveryTypes {
            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] query, completion, error in
                guard let self = self else { return }
                Analytics.logEvent("query_fired", parameters: ["sample_type": "\(type)"])
                Task {
                    for receiver in self.receivers { try await receiver.trigger() }
                    Analytics.logEvent("receivers_complete", parameters: ["sample_type": "\(type)"])
                    completion()
                }
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
        }
    }

    func registerBackgroundDeliveryReceiver(_ receiver: HealthKitBackgroundDeliveryReceiving) {
        receivers.append(receiver)
    }
}
