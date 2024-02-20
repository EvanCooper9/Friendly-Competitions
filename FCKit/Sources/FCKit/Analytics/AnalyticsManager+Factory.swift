import Factory

public extension Container {
    var analyticsManager: Factory<AnalyticsManaging> {
        self { AnalyticsManager() }.scope(.shared)
    }
}
