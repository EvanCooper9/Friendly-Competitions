extension Competition {
    enum ScoringModel: Int, CaseIterable, Codable, Identifiable {
        case percentOfGoals
        case rawNumbers

        var id: Int { rawValue }

        var displayName: String {
            switch self {
            case .percentOfGoals:
                return "Percent of Goals"
            case .rawNumbers:
                return "Raw numbers"
            }
        }

        var description: String {
            switch self {
            case .percentOfGoals:
                return "Every percent of an activity ring filled gains 1 point. Daily max of 600 points."
            case .rawNumbers:
                return "Every calorie, minute and hour gains 1 point. No daily max."
            }
        }

        func score(for activitySummary: ActivitySummary) -> Int {
            switch self {
            case .percentOfGoals:
                let energyPoints = activitySummary.activeEnergyBurned / activitySummary.activeEnergyBurnedGoal * 100
                let exercisePoints = activitySummary.appleExerciseTime / activitySummary.appleExerciseTimeGoal * 100
                let standPoints = activitySummary.appleStandHours / activitySummary.appleStandHoursGoal * 100
                return min(600, Int(energyPoints + exercisePoints + standPoints))
            case .rawNumbers:
                return Int(activitySummary.activeEnergyBurned + activitySummary.appleExerciseTime + activitySummary.appleStandHours)
            }
        }
    }

}