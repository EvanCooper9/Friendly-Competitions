import Foundation

// sourcery: AutoMockable
protocol ActivitySummaryCache {
    var activitySummary: ActivitySummary? { get set }
    var activitySummaries: [ActivitySummary.ID: ActivitySummary] { get set }
}

extension UserDefaults: ActivitySummaryCache {

    private enum Constants {
        static var activitySummaryKey: String { #function }
        static var activitySummariesKey: String { #function }
    }

    var activitySummary: ActivitySummary? {
        get { decode(ActivitySummary.self, forKey: Constants.activitySummaryKey) }
        set { encode(newValue, forKey: Constants.activitySummaryKey) }
    }

    var activitySummaries: [ActivitySummary.ID: ActivitySummary] {
        get { decode([ActivitySummary.ID: ActivitySummary].self, forKey: Constants.activitySummariesKey) ?? [:] }
        set { encode(newValue, forKey: Constants.activitySummariesKey) }
    }
}
