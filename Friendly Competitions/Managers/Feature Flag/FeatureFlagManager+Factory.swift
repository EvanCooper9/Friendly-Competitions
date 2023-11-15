import Factory

extension Container {
    var featureFlagManager: Factory<FeatureFlagManaging> {
        self { FeatureFlagManager() }.scope(.shared)
    }
}
