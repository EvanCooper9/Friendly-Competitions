import Factory
import Foundation

extension Container {
    var activitySummaryCache: Factory<ActivitySummaryCache> {
        Factory(self) { UserDefaults.standard }.scope(.shared)
    }

    var activitySummaryManager: Factory<ActivitySummaryManaging> {
        Factory(self) { ActivitySummaryManager() }.scope(.shared)
    }
}
