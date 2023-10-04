protocol FeatureFlag {
    associatedtype Data
    var stringValue: String { get }
    var defaultValue: Data { get }
}

enum FeatureFlagDouble: String, FeatureFlag {
    typealias Data = Double

    case databaseCacheTtl = "database_cache_ttl"

    var stringValue: String { rawValue }
    var defaultValue: Data {
        switch self {
        case .databaseCacheTtl:
            return 5.days
        }
    }
}

enum FeatureFlagBool: String, FeatureFlag {
    typealias Data = Bool

    case premiumEnabled = "premium_enabled"

    var stringValue: String { rawValue }
    var defaultValue: Bool {
        switch self {
        case .premiumEnabled:
            return false
        }
    }
}
