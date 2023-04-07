import Factory

extension Container {
    var appServices: Factory<[AppService]> {
        self {
            .build {
                FirebaseAppService()
                FeatureFlagAppService()
                RevenueCatAppService()
                DeveloperAppService()
            }
        }
        .scope(.singleton)
    }
}
