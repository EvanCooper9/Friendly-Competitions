import Factory
import Foundation
import HealthKit

extension Container {
    var healthStore: Factory<HealthStoring> {
        self { HKHealthStore() }.scope(.shared)
    }

    var healthKitManager: Factory<HealthKitManaging> {
        self { HealthKitManager() }.scope(.shared)
    }
}
