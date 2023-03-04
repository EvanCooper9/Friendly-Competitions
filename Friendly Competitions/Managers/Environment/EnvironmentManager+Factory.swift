import Factory

extension Container {
    static let environmentManager = Factory<EnvironmentManaging>(scope: .singleton, factory: EnvironmentManager.init)
}
