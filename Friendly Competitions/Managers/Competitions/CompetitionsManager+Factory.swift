import Factory
import Foundation

extension Container {
    var competitionCache: Factory<CompetitionCache> {
        Factory(self) { UserDefaults.standard }.scope(.shared)
    }
    
    var competitionsManager: Factory<CompetitionsManaging> {
        Factory(self) { CompetitionsManager() }.scope(.shared)
    }
}
