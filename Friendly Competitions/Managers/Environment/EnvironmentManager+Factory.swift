import Factory
import Foundation

extension Container {
    var environmentCache: Factory<EnvironmentCache> {
        Factory(self) { UserDefaults.standard }.scope(.shared)
    }
    
    var environmentManager: Factory<EnvironmentManaging> {
        Factory(self) { EnvironmentManager() }.scope(.shared)
    }
}
