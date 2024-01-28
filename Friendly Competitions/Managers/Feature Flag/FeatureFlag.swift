protocol FeatureFlag {
    associatedtype Data
    var stringValue: String { get }
}

enum FeatureFlagDouble: String, FeatureFlag {
    typealias Data = Double

    case databaseCacheTtl = "database_cache_ttl"
    case healthKitBackgroundDeliveryTimeoutMS = "health_kit_background_delivery_timeout_ms"

    var stringValue: String { rawValue }
}

enum FeatureFlagBool: String, FeatureFlag {
    typealias Data = Bool

    case premiumEnabled = "premium_enabled"
    case newResultsBannerEnabled = "new_results_banner_enabled"

    var stringValue: String { rawValue }
}
