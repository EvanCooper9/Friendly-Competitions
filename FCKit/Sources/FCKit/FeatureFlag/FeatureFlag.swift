public protocol FeatureFlag: CaseIterable, RawRepresentable {
    associatedtype Data: Codable
    var stringValue: String { get }
    var defaultValue: Data { get }
}

extension FeatureFlag where RawValue == String {
    public var stringValue: String { rawValue }
}

public enum FeatureFlagBool: String, CaseIterable, FeatureFlag {
    public typealias Data = Bool

    case adsEnabled = "ads_enabled"
    case newResultsBannerEnabled = "new_results_banner_enabled"
    case sharedBackgroundDeliveryPublishers = "shared_background_delivery_publishers"
    case ignoreManuallyEnteredHealthKitData = "ignore_manually_entered_health_kit_data"

    public var defaultValue: Data { false }
}

public enum FeatureFlagDouble: String, FeatureFlag {
    public typealias Data = Double

    case databaseCacheTtl = "database_cache_ttl"
    case healthKitBackgroundDeliveryTimeoutMS = "health_kit_background_delivery_timeout_ms"
    case widgetUpdateIntervalS = "widget_update_interval_s"
    case dataUploadGracePeriodHours = "data_upload_grace_period_hours"

    public var defaultValue: Data { 0 }
}

public enum FeatureFlagString: String, FeatureFlag {
    public typealias Data = String

    case googleAdsHomeScreenAdUnit = "google_ads_home_screen_ad_unit"
    case googleAdsExploreScreenAdUnit = "google_ads_explore_screen_ad_unit"

    public var defaultValue: Data { "" }
}
