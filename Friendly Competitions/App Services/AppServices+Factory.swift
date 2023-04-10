import Factory

extension Container {
    var appServices: Factory<[AppService]> {
        self {
            .build {
                FirebaseAppService()
                RevenueCatAppService()
                DeveloperAppService()
            }
        }
        .scope(.singleton)
    }
}
