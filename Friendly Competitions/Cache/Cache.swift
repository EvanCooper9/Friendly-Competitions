import Foundation

// sourcery: AutoMockable
protocol Cache {
    var activitySummary: ActivitySummary? { get set }
}

extension UserDefaults: Cache {
    
    private enum Constants {
        static var activitySummaryKey: String { #function }
    }
    
    var activitySummary: ActivitySummary? {
        get { decode(ActivitySummary.self, forKey: Constants.activitySummaryKey) }
        set { encode(newValue, forKey: Constants.activitySummaryKey) }
    }
}
