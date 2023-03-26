enum CompetitionResultsDataPoint: Identifiable {

    struct Standing: Identifiable {
        let userId: User.ID
        let rank: Int
        let points: Int
        let isHighlighted: Bool

        var id: User.ID { userId }
    }

    case rank(current: Int, previous: Int?)
    case standings([Standing])
    case points(current: Int, previous: Int?)
    case activitySummaryBestDay(ActivitySummary?)
    case activitySummaryCloseCount(current: Int, previous: Int?)
    case workoutsBestDay(Workout?)

    var id: String {
        switch self {
        case let .rank(current, previous):
            return "rank-\(current)-\(previous ?? 0)"
        case .standings:
            return "standings"
        case let .points(current, previous):
            return "points-\(current)-\(previous ?? 0)"
        case .activitySummaryBestDay:
            return "activity-summary-best-day"
        case .activitySummaryCloseCount:
            return "activity-summary-close-count"
        case .workoutsBestDay:
            return "workouts-best-day"
        }
    }

    var title: String {
        switch self {
        case .rank:
            return L10n.Results.Rank.title
        case .standings:
            return L10n.Results.Standings.title
        case .points:
            return L10n.Results.Points.title
        case .activitySummaryBestDay, .activitySummaryCloseCount:
            return L10n.Results.ActivitySummaries.title
        case .workoutsBestDay:
            return L10n.Results.Workouts.title
        }
    }
}
