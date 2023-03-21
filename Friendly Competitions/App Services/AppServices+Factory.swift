import Factory

extension Container {
    var appServices: Factory<[AppService]> {
        Factory(self) {
            [
                FirebaseAppService(),
                RevenueCatAppService()
            ]
        }
        .scope(.singleton)
    }
}
