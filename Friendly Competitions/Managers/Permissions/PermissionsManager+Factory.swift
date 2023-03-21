import Factory

extension Container {
    var permissionsManager: Factory<PermissionsManaging> {
        Factory(self) { PermissionsManager() }.scope(.shared)
    }
}
