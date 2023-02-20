import Factory

extension Container {
    static let authenticationManager = Factory<AuthenticationManaging>(scope: .shared, factory: AuthenticationManager.init)
}
