import GoogleMobileAds

final class GoogleAdsAppService: AppService {
    func didFinishLaunching() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "cb8a077fbc58b21f39101e8a480471b4" ]
    }
}
