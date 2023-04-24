import Factory

extension Container {
    var healthKitDataHelperBuilder: Factory<HealthKitDataHelperBuilding> {
        self { HealthKitDataHelperBuilder() }.scope(.shared)
    }
}
