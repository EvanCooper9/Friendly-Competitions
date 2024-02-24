import ECKit
import Factory
import GoogleMobileAds

enum GoogleAdUnit {
    case native(unit: String)

    var identifier: String {
        switch self {
        case .native(let unit):
            let environment = Container.shared.environmentManager.resolve().environment
            if environment.isDebug {
                // https://developers.google.com/admob/ios/test-ads#demo_ad_units
//                 return "ca-app-pub-3940256099942544/3986624511" // native
                return "ca-app-pub-3940256099942544/2521693316" // native video
            } else {
                return unit
            }
        }
    }

    var adTypes: [GADAdLoaderAdType] {
        switch self {
        case .native:
            return [.native]
        }
    }
}
