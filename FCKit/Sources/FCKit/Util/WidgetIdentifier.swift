import ECKit
import Foundation

public enum WidgetIdentifier {
    private enum Constants {
        static let widgetSuffix = ".FriendlyCompetitionsWidgets"
        static let competitionStandingsWidgetSuffix = ".CompetitionStandingsWidget"
    }

    case competitionStandings

    public func id(bundleIdentifier: String = Bundle.main.id) -> String {
        switch self {
        case .competitionStandings:
            if bundleIdentifier.hasSuffix(Constants.widgetSuffix) {
                let value = "group." + bundleIdentifier + Constants.competitionStandingsWidgetSuffix
                print(bundleIdentifier, value)
                return value
            } else {
                let value = "group." + bundleIdentifier + Constants.widgetSuffix + Constants.competitionStandingsWidgetSuffix
                print(bundleIdentifier, value)
                return value
            }
        }
    }
}
