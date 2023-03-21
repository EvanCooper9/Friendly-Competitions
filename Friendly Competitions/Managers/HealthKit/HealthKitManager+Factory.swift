import Factory
import Foundation
import HealthKit

extension Container {
    var healthStore: Factory<HealthStoring>{
        Factory(self) { HKHealthStore() }.scope(.shared)
    }
    
    var healthKitManager: Factory<HealthKitManaging>{
        Factory(self) { HealthKitManager() }.scope(.shared)
    }
    
    var healthKitManagerCache: Factory<HealthKitManagerCache>{
        Factory(self) { UserDefaults.standard }.scope(.shared)
    }
}
