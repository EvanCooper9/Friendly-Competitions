import ECKit
import Foundation

public enum AppGroup {

    private enum Constants {
        static let widgetSuffix = ".FriendlyCompetitionsWidgets"
    }

    public static func id(bundleIdentifier: String = Bundle.main.id) -> String {
        let value = "group." + (bundleIdentifier.before(suffix: Constants.widgetSuffix) ?? bundleIdentifier)
        print(bundleIdentifier, value)
        return value
    }
}
