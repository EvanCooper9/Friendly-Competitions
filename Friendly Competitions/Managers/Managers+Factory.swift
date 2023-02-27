import Factory

extension Container {
    static let usersCache = Factory<UsersCache>(scope: .shared, factory: UsersStore.init)
}
