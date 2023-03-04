import Factory

extension Container {
    static let friendsManager = Factory<FriendsManaging>(scope: .shared, factory: FriendsManager.init)
}
