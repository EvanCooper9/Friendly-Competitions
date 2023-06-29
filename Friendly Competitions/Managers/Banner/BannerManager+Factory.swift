import Factory

extension Container {
    var bannerManager: Factory<BannerManaging> {
        self { BannerManager() }.scope(.shared)
    }
}
