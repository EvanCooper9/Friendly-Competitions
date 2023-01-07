enum CompetitionHistoryDataPoint: Identifiable {
    
    struct Standing {
        let rank: Int
        let points: Int
        let isHighlighted: Bool
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
            return "Rank \(current) \(previous ?? 0)"
        case .standings:
            return "Standings"
        case let .points(current, previous):
            return "Points \(current) \(previous ?? 0)"
        case .activitySummaryBestDay:
            return "Activity Summary Best Day"
        case .activitySummaryCloseCount:
            return "Activity Summary Close Count"
        case .workoutsBestDay:
            return "Workouts Best Day"
        }
    }
    
    var title: String {
        switch self {
        case .rank:
            return "Rank"
        case .standings:
            return "Standings"
        case .points:
            return "Points"
        case .activitySummaryBestDay, .activitySummaryCloseCount:
            return "Rings"
        case .workoutsBestDay:
            return "Workouts"
        }
    }
}
