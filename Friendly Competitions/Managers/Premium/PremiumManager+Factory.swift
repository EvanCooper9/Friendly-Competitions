import Factory

extension Container {
    var premiumManager: Factory<PremiumManaging> {
        self { PremiumManager() }.scope(.shared)
    }
}
