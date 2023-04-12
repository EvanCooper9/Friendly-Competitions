import Factory
import Foundation

extension Container {
    var competitionCache: Factory<CompetitionCache> {
        self { UserDefaults.standard }.scope(.shared)
    }

    var competitionsManager: Factory<CompetitionsManaging> {
        self { CompetitionsManager() }.scope(.shared)
    }
}
