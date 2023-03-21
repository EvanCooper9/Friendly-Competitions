import Factory

extension Container {
    var premiumManager: Factory<PremiumManaging> {
        Factory(self) { PremiumManager() }.scope(.shared)
    }
}
