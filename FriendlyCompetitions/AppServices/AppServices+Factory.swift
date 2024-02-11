import Factory

extension Container {
    var appServices: Factory<[AppService]> {
        self {
            .build {
                FirebaseAppService()
                RevenueCatAppService()
                DeveloperAppService()
                DataUploadingAppService()
                NotificationsAppService()
                BackgroundJobsAppService()
                GoogleAdsAppService()
            }
        }
        .scope(.singleton)
    }
}
