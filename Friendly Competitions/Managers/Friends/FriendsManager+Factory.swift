import Factory

extension Container {
    var friendsManager: Factory<FriendsManaging> {
        Factory(self) { FriendsManager() }.scope(.shared)
    }
}
