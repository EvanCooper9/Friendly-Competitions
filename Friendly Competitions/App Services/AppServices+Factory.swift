import Factory

extension Container {
    var appServices: Factory<[AppService]> {
        Factory(self) {
            .build {
                FirebaseAppService()
                RevenueCatAppService()
                DeveloperAppService()
            }
        }
        .scope(.singleton)
    }
}
