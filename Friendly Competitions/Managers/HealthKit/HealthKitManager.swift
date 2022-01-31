import Combine
import HealthKit
import Resolver
import SwiftUI

class AnyHealthKitManager: ObservableObject {
    var permissionStatus: PermissionStatus { .authorized }
    func execute(_ query: HKQuery) {}
    func requestPermissions(_ completion: @escaping (PermissionStatus) -> Void) {}
    func registerForBackgroundDelivery() {}
    func registerBackgroundDeliveryReceiver(_ backgroundDeliverReceiver: HealthKitBackgroundDeliveryReceiving) {}
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

    private let healthStore = HKHealthStore()
    private var hasRegisteredForBackgroundDelivery = false
    private var backgroundDeliverReceivers = [HealthKitBackgroundDeliveryReceiving]()
    private var backgroundDeliveryCancellables = Set<AnyCancellable>()
    private let backgroundDeliveryTrigger = PassthroughSubject<HKObserverQueryCompletionHandler?, Never>()

    @AppStorage("healthKitStoredPermissionStatus") private var storedPermissionStatus: PermissionStatus?

    private var notDeterminedPermissions: [HKObjectType] {
        Constants.permissionObjectTypes.filter { healthStore.authorizationStatus(for: $0) == .notDetermined }
    }

    private var updateTask: Task<Void, Error>? {
        willSet { updateTask?.cancel() }
    }

    // MARK: - Lifecycle

    override init() {
        super.init()
        
        backgroundDeliveryTrigger
            .scan(nil, { completionHandlers, completionHandler -> [HKObserverQueryCompletionHandler]? in
                guard let completionHandler = completionHandler else { return nil }
                return (completionHandlers ?? []).appending(completionHandler)
            })
            .compactMap { $0 }
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink { [weak self] completionHandlers in
                guard let self = self else { return }
                guard !completionHandlers.isEmpty else {
                    self.backgroundDeliveryTrigger.send(nil)
                    return
                }
                Task {
                    for receiver in self.backgroundDeliverReceivers {
                        try await receiver.trigger()
                    }
                    completionHandlers.forEach { $0() }
                    self.backgroundDeliveryTrigger.send(nil)
                }
            }
            .store(in: &backgroundDeliveryCancellables)
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
                DispatchQueue.main.async {
                    self.storedPermissionStatus = permissionStatus
                }
                completion(permissionStatus)
            }
        )
    }

    override func registerForBackgroundDelivery() {
        guard notDeterminedPermissions.isEmpty else { return }
        guard !hasRegisteredForBackgroundDelivery else {
            backgroundDeliveryTrigger.send({})
            return
        }

        for sampleType in Constants.backgroundDeliveryTypes {
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] query, completion, error in
                guard let self = self else { return }
                self.backgroundDeliveryTrigger.send(completion)
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
