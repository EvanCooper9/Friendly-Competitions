// sourcery: AutoMockable
protocol UsersCache {
    var users: [User.ID: User] { get set }
}

final class UsersStore: UsersCache {
    var users = [User.ID : User]()
}
