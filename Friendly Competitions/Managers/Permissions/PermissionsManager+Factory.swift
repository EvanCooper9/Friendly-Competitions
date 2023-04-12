import Factory

extension Container {
    var permissionsManager: Factory<PermissionsManaging> {
        self { PermissionsManager() }.scope(.shared)
    }
}
