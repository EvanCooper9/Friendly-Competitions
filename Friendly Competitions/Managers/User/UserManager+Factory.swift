import Factory

extension Container {
    var userManager: Factory<UserManaging> {
        Factory(self) { fatalError("User manager not initialized") }
    }
}
