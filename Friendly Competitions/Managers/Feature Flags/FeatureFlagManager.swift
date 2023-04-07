import Combine
import CombineExt
import FirebaseRemoteConfig
import FirebaseRemoteConfigSwift
import ECKit

enum IntFeatureFlag: String {
    case standingsRankUpdateInterval = "standings_rank_update_interval"
}

// sourcery: AutoMockable
protocol FeatureFlagManaging {
    func activate()
    func value(for flag: IntFeatureFlag) -> Int?
}

final class FeatureFlagManager: FeatureFlagManaging {

    private let config = RemoteConfig.remoteConfig()

    func activate() {
        config.fetchAndActivate()
    }

    func value(for flag: IntFeatureFlag) -> Int? {
        config.configValue(forKey: flag.rawValue).numberValue as? Int
    }
}
