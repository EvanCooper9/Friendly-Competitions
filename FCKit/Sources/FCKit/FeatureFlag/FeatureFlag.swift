protocol FeatureFlag: RawRepresentable {
    associatedtype Data
    var stringValue: String { get }
}

extension FeatureFlag where RawValue == String {
    var stringValue: String { rawValue }
}

public enum FeatureFlagDouble: String, FeatureFlag {
    typealias Data = Double

    case databaseCacheTtl = "database_cache_ttl"
    case healthKitBackgroundDeliveryTimeoutMS = "health_kit_background_delivery_timeout_ms"
    case widgetUpdateIntervalS = "widget_update_interval_s"
}

public enum FeatureFlagBool: String, FeatureFlag {
    typealias Data = Bool

    case adsEnabled = "ads_enabled"
    case premiumEnabled = "premium_enabled"
    case newResultsBannerEnabled = "new_results_banner_enabled"
    case sharedBackgroundDeliveryPublishers = "shared_background_delivery_publishers"
}
