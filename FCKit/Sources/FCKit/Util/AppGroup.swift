import ECKit
import Foundation

public enum AppGroup {

    private enum Constants {
        static let widgetIdentifier = "FriendlyCompetitionsWidgets"
    }

    public static func id(bundleIdentifier: String = Bundle.main.id) -> String {
        let withoutWidgetIdentifier = bundleIdentifier
            .split(separator: ".")
            .filter { $0 != Constants.widgetIdentifier }
            .joined(separator: ".")
        return "group." + withoutWidgetIdentifier
    }
}
