import Factory

extension Container {
    static let premiumManager = Factory<PremiumManaging>(scope: .shared, factory: PremiumManager.init)
}
