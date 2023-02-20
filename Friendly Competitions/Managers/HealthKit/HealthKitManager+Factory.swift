import Factory

extension Container {
    static let healthKitManager = Factory<HealthKitManaging>(scope: .shared, factory: HealthKitManager.init)
}
