import Factory

extension Container {
    var backgroundRefreshManager: Factory<BackgroundRefreshManaging> {
        self { BackgroundRefreshManager() }.scope(.shared)
    }
}
