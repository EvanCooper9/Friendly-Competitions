import Factory

extension Container {
    var userManager: Factory<UserManaging> {
        self { fatalError("User manager not initialized") }
    }
}
