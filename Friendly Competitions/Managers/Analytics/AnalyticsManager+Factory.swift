import Factory

extension Container {
    static let analyticsManager = Factory<AnalyticsManaging>(scope: .shared, factory: AnalyticsManager.init)
}
