import Factory

extension Container {
    var deepLinkManager: Factory<DeepLinkManaging> {
        self { DeepLinkManager() }.scope(.shared)
    }
}
