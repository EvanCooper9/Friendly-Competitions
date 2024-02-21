import Factory
import Foundation

public extension Container {
    var environmentCache: Factory<EnvironmentCache> {
        self { UserDefaults.appGroup }.scope(.shared)
    }

    var environmentManager: Factory<EnvironmentManaging> {
        self { EnvironmentManager() }.scope(.singleton)
    }
}
