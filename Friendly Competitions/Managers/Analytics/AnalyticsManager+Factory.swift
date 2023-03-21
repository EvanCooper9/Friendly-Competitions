import Factory

extension Container {
    var analyticsManager: Factory<AnalyticsManaging> {
        Factory(self) { AnalyticsManager() }.scope(.shared)
    }
}
