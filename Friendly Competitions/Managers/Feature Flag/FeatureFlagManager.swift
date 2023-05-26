import Foundation
import FirebaseRemoteConfig
import FirebaseRemoteConfigSwift

protocol FeatureFlagManaging {
    func value<T: FeatureFlag>(for featureFlag: T) -> T.Data
}

final class FeatureFlagManager: FeatureFlagManaging {

    private let remoteConfig = RemoteConfig.remoteConfig()

    init() {
        remoteConfig.fetch { status, error -> Void in
            if let error {
                error.reportToCrashlytics()
            } else if status == .success {
                self.remoteConfig.activate { _, error in
                    guard let error else { return }
                    error.reportToCrashlytics()
                }
            }
        }
    }

    func value<T: FeatureFlag>(for featureFlag: T) -> T.Data {
        let configValue = remoteConfig.configValue(forKey: featureFlag.stringValue)
        if T.Data.self == Double.self {
            return configValue.numberValue.doubleValue as? T.Data ?? featureFlag.defaultValue
        } else if T.Data.self == Bool.self {
            return configValue.boolValue as? T.Data ?? featureFlag.defaultValue
        } else if T.Data.self == Int.self {
            return configValue.numberValue.intValue as? T.Data ?? featureFlag.defaultValue
        } else if T.Data.self == String.self {
            return configValue.stringValue as? T.Data ?? featureFlag.defaultValue
        }
        return featureFlag.defaultValue
    }
}
