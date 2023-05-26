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
