import HealthKit

final class MockActivitySummaryManager: ActivitySummaryManaging {

    var activitySummaries: [ActivitySummary] = [.mock]
    private var hkActivitySummaries: [HKActivitySummary] { activitySummaries.map(\.hkActivitySummary) }

    private(set) var handlers = [([HKActivitySummary]) -> Void]()
    private(set) var didRegisterForBackgroundDelivery = false

    func addHandler(_ handler: @escaping ([HKActivitySummary]) -> Void) {
        handler(hkActivitySummaries)
        handlers.append(handler)
    }

    func registerForBackgroundDelivery() {
        didRegisterForBackgroundDelivery = true
    }
}
