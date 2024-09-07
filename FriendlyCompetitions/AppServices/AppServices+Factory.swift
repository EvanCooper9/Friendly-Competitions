import Factory

extension Container {
    var appServices: Factory<[AppService]> {
        self {
            .build {
                FirebaseAppService()
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
