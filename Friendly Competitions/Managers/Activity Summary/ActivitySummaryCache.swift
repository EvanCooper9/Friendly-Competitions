import Foundation

// sourcery: AutoMockable
protocol ActivitySummaryCache {
    var activitySummary: ActivitySummary? { get set }
}

extension UserDefaults: ActivitySummaryCache {

    private enum Constants {
        static var activitySummaryKey: String { #function }
    }

    var activitySummary: ActivitySummary? {
        get { decode(ActivitySummary.self, forKey: Constants.activitySummaryKey) }
        set { encode(newValue, forKey: Constants.activitySummaryKey) }
    }
}
