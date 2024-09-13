public enum FeatureFlagDouble: String, FeatureFlag {
    public typealias Data = Double

    case databaseCacheTtl = "database_cache_ttl"
    case healthKitBackgroundDeliveryTimeoutMS = "health_kit_background_delivery_timeout_ms"
    case widgetUpdateIntervalS = "widget_update_interval_s"
    case dataUploadGracePeriodHours = "data_upload_grace_period_hours"

    public var defaultValue: Data { 0 }
}
