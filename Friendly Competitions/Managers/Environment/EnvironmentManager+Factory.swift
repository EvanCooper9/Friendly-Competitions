import Factory
import Foundation

extension Container {
    var environmentCache: Factory<EnvironmentCache> {
        self { UserDefaults.standard }.scope(.shared)
    }

    var environmentManager: Factory<EnvironmentManaging> {
        self { EnvironmentManager() }.scope(.shared)
    }
}
