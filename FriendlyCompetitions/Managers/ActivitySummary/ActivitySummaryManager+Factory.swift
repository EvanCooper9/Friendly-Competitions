import Factory
import Foundation

extension Container {
    var activitySummaryCache: Factory<ActivitySummaryCache> {
        self { UserDefaults.standard }.scope(.shared)
    }

    var activitySummaryManager: Factory<ActivitySummaryManaging> {
        self { ActivitySummaryManager() }.scope(.shared)
    }
}
