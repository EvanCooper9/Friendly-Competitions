import Factory
import Foundation

extension Container {
    static let activitySummaryManager = Factory<ActivitySummaryManaging>(scope: .shared, factory: ActivitySummaryManager.init)
    static let activitySummaryCache = Factory<ActivitySummaryCache>(scope: .shared) { UserDefaults.standard }
}
