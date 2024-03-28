import ECKit
import Foundation
import FirebaseRemoteConfig

// sourcery: AutoMockable
public protocol FeatureFlagManaging {
    func value(forBool featureFlag: FeatureFlagBool) -> Bool
    func value(forDouble featureFlag: FeatureFlagDouble) -> Double
    func value(forString featureFlag: FeatureFlagString) -> String
    func override(flag: FeatureFlagBool, with value: Bool?)
    func override(flag: FeatureFlagDouble, with value: Double?)
    func override(flag: FeatureFlagString, with value: String?)
    func isOverridden(flag: FeatureFlagBool) -> Bool
    func isOverridden(flag: FeatureFlagDouble) -> Bool
    func isOverridden(flag: FeatureFlagString) -> Bool
}

final class FeatureFlagManager: FeatureFlagManaging {

    private let remoteConfig = RemoteConfig.remoteConfig()

    private enum StoredValue: Codable {
        case bool(Bool)
        case double(Double)
        case string(String)
    }

    @UserDefault("feature_flag_overrides", defaultValue: [String: StoredValue](), container: .appGroup)
    private var overrides

    init() {
        remoteConfig.fetch(withExpirationDuration: 0) { status, error -> Void in
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
        value(for: featureFlag)
    }

    func value(forDouble featureFlag: FeatureFlagDouble) -> Double {
        value(for: featureFlag)
    }

    func value(forString featureFlag: FeatureFlagString) -> String {
        value(for: featureFlag)
    }

    func isOverridden(flag: FeatureFlagBool) -> Bool {
        overrides[flag.stringValue] != nil
    }

    func isOverridden(flag: FeatureFlagDouble) -> Bool {
        overrides[flag.stringValue] != nil
    }

    func isOverridden(flag: FeatureFlagString) -> Bool {
        overrides[flag.stringValue] != nil
    }

    func override(flag: FeatureFlagBool, with value: Bool?) {
        if let value {
            overrides[flag.stringValue] = .bool(value)
        } else {
            overrides[flag.stringValue] = nil
        }
    }

    func override(flag: FeatureFlagDouble, with value: Double?) {
        if let value {
            overrides[flag.stringValue] = .double(value)
        } else {
            overrides[flag.stringValue] = nil
        }
    }

    func override(flag: FeatureFlagString, with value: String?) {
        if let value {
            overrides[flag.stringValue] = .string(value)
        } else {
            overrides[flag.stringValue] = nil
        }
    }

    // MARK: - Private

    private func value<F>(for flag: F) -> F.Data where F : FeatureFlag {
        if let override = overrides[flag.stringValue] {
            switch override {
            case .bool(let bool):
                if let value = bool as? F.Data {
                    return value
                }
            case .double(let double):
                if let value = double as? F.Data {
                    return value
                }
            case .string(let string):
                if let value = string as? F.Data {
                    return value
                }
            }
        }
        let value = remoteConfig.configValue(forKey: flag.stringValue)
        if F.Data.self == Bool.self {
            return value.boolValue as! F.Data
        } else if F.Data.self == Double.self {
            return value.numberValue.doubleValue as! F.Data
        } else if F.Data.self == String.self {
            return value.stringValue as! F.Data
        }
        return flag.defaultValue
    }
}
