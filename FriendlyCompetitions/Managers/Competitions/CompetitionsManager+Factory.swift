import Factory
import Foundation

extension Container {
    var competitionsManager: Factory<CompetitionsManaging> {
        self { CompetitionsManager() }.scope(.shared)
    }
}
