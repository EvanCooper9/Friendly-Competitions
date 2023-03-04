import Factory
import Foundation
import HealthKit

extension Container {
    static let healthStore = Factory<HealthStoring>(scope: .shared, factory: HKHealthStore.init)
    static let healthKitManager = Factory<HealthKitManaging>(scope: .shared, factory: HealthKitManager.init)
    static let healthKitManagerCache = Factory<HealthKitManagerCache>(scope: .shared) { UserDefaults.standard }
}
