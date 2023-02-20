import Factory

extension Container {
    static let permissionsManager = Factory<PermissionsManaging>(scope: .shared, factory: PermissionsManager.init)
}
