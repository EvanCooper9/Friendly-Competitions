import Factory

extension Container {
    static let userManager = Factory<UserManaging>(scope: .shared) { fatalError("User manager not initialized") }
}
