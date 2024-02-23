import ECKit
import GoogleMobileAds

enum GoogleAdUnit {
    case native

    var identifier: String {
        switch self {
        case .native:
            if Bundle.main.id.contains("debug") {
                // https://developers.google.com/admob/ios/test-ads#demo_ad_units
                // return "ca-app-pub-3940256099942544/3986624511" // native
                return "ca-app-pub-3940256099942544/2521693316" // native video
            } else {
                return "ca-app-pub-9171629407679521/4967897824"
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
