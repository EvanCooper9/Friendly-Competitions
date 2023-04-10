import Factory

extension Container {
    var friendsManager: Factory<FriendsManaging> {
        self { FriendsManager() }.scope(.shared)
    }
}
