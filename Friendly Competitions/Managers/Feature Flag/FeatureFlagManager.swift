import Foundation
import FirebaseRemoteConfig

// sourcery: AutoMockable
protocol FeatureFlagManaging {
    func value(forBool featureFlagBool: FeatureFlagBool) -> Bool
    func value(forDouble featureFlagDouble: FeatureFlagDouble) -> Double
}

final class FeatureFlagManager: FeatureFlagManaging {

    private let remoteConfig = RemoteConfig.remoteConfig()

    init() {
        remoteConfig.fetch { status, error -> Void in
            if let error {
                error.reportToCrashlytics()
            } else if status == .success {
                self.remoteConfig.activate { _, error in
                    error?.reportToCrashlytics()
                }
            }
        }
    }

    func value(forBool featureFlag: FeatureFlagBool) -> Bool {
        let value = remoteConfig.configValue(forKey: featureFlag.stringValue).boolValue
        print("feature flag manager", featureFlag, value)
        return value
    }

    func value(forDouble featureFlag: FeatureFlagDouble) -> Double {
        remoteConfig.configValue(forKey: featureFlag.stringValue).numberValue.doubleValue
    }
}
