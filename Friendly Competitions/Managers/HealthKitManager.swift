import Combine
import HealthKit
import Resolver
import SwiftUI

// sourcery: AutoMockable
protocol HealthKitManaging {
    var backgroundDeliveryReceived: AnyPublisher<Void, Never> { get }
    var permissionStatus: AnyPublisher<PermissionStatus, Never> { get }
    func execute(_ query: HKQuery)
    func requestPermissions()
}

final class HealthKitManager: HealthKitManaging {

    private enum Constants {
        static var backgroundDeliveryTypes: [HKSampleType] {
            permissionObjectTypes.compactMap { $0 as? HKSampleType }
        }

        static let permissionObjectTypes: [HKObjectType] = {
            let basicTypes = [
                HKQuantityType(.activeEnergyBurned),
                HKQuantityType(.appleExerciseTime),
                HKQuantityType(.appleMoveTime),
                HKQuantityType(.appleStandTime),
                HKCategoryType(.appleStandHour),
                .workoutType(),
                .activitySummaryType(), // isn't delivered via background
            ]
            
            let workoutSampleTypes = HKWorkoutActivityType.supported
                .map(\.samples)
                .flatMap { $0 }
            
            return basicTypes.appending(contentsOf: workoutSampleTypes.map(\.0))
        }()
    }

    // MARK: - Public Properties

    var backgroundDeliveryReceived: AnyPublisher<Void, Never> { _backgroundDeliveryReceived.eraseToAnyPublisher() }
    var permissionStatus: AnyPublisher<PermissionStatus, Never> { storedPermissionStatus.publisher.eraseToAnyPublisher() }

    // MARK: - Private Properties
    
    @Injected private var analyticsManager: AnalyticsManaging

    private let healthStore = HKHealthStore()
    private var hasRegisteredForBackgroundDelivery = false
    private let _backgroundDeliveryReceived = PassthroughSubject<Void, Never>()

    @AppStorage("healthKitStoredPermissionStatus") private var storedPermissionStatus: PermissionStatus?

    private var notDeterminedPermissions: [HKObjectType] {
        Constants.permissionObjectTypes.filter { healthStore.authorizationStatus(for: $0) == .notDetermined }
    }

    // MARK: - Initializers

    init() {
        if notDeterminedPermissions.isEmpty { storedPermissionStatus = .done }
        registerForBackgroundDelivery()
    }

    // MARK: - Public Methods

    func execute(_ query: HKQuery) {
        healthStore.execute(query)
    }

    func requestPermissions() {
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
                self.storedPermissionStatus = permissionStatus
            }
        )
    }

    // MARK: - Private Methods

    private func registerForBackgroundDelivery() {
        guard storedPermissionStatus == .authorized || storedPermissionStatus == .done else { return }
        guard !hasRegisteredForBackgroundDelivery else {
            _backgroundDeliveryReceived.send()
            return
        }

        for sampleType in Constants.backgroundDeliveryTypes {
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] query, completion, error in
                guard let self = self else { return }
                self._backgroundDeliveryReceived.send()
                completion()
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { _, _ in }
        }
        hasRegisteredForBackgroundDelivery.toggle()
    }
}
