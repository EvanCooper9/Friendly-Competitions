public enum WidgetIdentifier: String {
    case competitionStandings

    public var rawValue: String {
        switch self {
        case .competitionStandings:
            #if DEBUG
            return "com.evancooper.FriendlyCompetitions.debug.CompetitionStandingsWidget"
            #else
            return "com.evancooper.FriendlyCompetitions.CompetitionStandingsWidget"
            #endif
        }
    }
}
