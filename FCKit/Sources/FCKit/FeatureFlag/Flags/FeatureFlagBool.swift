public enum FeatureFlagBool: String, CaseIterable, FeatureFlag {
    public typealias Data = Bool

    case adsEnabled = "ads_enabled"
    case newResultsBannerEnabled = "new_results_banner_enabled"
    case ignoreManuallyEnteredHealthKitData = "ignore_manually_entered_health_kit_data"

    public var defaultValue: Data { false }
}
