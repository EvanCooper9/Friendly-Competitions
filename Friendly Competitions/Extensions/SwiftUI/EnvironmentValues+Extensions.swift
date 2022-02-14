import SwiftUI

extension EnvironmentValues {
    var deepLink: DeepLink? {
        get { self[DeepLinkKey.self] }
        set { self[DeepLinkKey.self] = newValue }
    }
}

private struct DeepLinkKey: EnvironmentKey {
    static let defaultValue = DeepLink?.none
}
