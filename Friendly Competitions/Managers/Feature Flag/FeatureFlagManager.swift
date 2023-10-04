import Foundation
import FirebaseRemoteConfig
import FirebaseRemoteConfigSwift

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
                    guard let error else { return }
                    error.reportToCrashlytics()
                }
            }
        }
    }

    func value(forBool featureFlag: FeatureFlagBool) -> Bool {
        remoteConfig.configValue(forKey: featureFlag.stringValue).boolValue
    }

    func value(forDouble featureFlag: FeatureFlagDouble) -> Double {
        remoteConfig.configValue(forKey: featureFlag.stringValue).numberValue.doubleValue
    }
}
