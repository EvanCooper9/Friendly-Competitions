import Factory

extension Container {
    var appServices: Factory<[AppService]> {
        self {
            [
                FirebaseAppService(),
                FeatureFlagAppService(),
                RevenueCatAppService(),
                DeveloperAppService()
            ]
        }
        .scope(.singleton)
    }
}
