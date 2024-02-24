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
                return "group." + bundleIdentifier + Constants.competitionStandingsWidgetSuffix
            } else {
                return "group." + bundleIdentifier + Constants.widgetSuffix + Constants.competitionStandingsWidgetSuffix
            }
        }
    }
}
