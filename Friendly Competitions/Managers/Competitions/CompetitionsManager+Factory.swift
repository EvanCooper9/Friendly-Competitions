import Factory
import Foundation

extension Container {
    static let competitionsManager = Factory<CompetitionsManaging>(scope: .shared, factory: CompetitionsManager.init)
    static let competitionCache = Factory<CompetitionCache>(scope: .shared) { UserDefaults.standard }
}
