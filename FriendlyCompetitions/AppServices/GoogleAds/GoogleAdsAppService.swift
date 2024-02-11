import GoogleMobileAds

final class GoogleAdsAppService: AppService {
    func didFinishLaunching() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}
