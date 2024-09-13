import Foundation

public enum FeatureFlagString: String, FeatureFlag {
    public typealias Data = String

    case googleAdsHomeScreenAdUnit = "google_ads_home_screen_ad_unit"
    case googleAdsExploreScreenAdUnit = "google_ads_explore_screen_ad_unit"
    case minimumAppVersion = "ios_minimum_app_version"

    public var defaultValue: Data {
        switch self {
        case .googleAdsHomeScreenAdUnit: return ""
        case .googleAdsExploreScreenAdUnit: return ""
        case .minimumAppVersion: return Bundle.main.version
        }
    }
}
