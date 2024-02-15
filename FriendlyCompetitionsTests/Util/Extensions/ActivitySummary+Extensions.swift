import Foundation

@testable import FriendlyCompetitions

extension ActivitySummary {
    func with(date: Date) -> ActivitySummary {
        .init(
            activeEnergyBurned: activeEnergyBurned,
            appleExerciseTime: appleExerciseTime,
            appleStandHours: appleStandHours,
            activeEnergyBurnedGoal: activeEnergyBurnedGoal,
            appleExerciseTimeGoal: appleExerciseTimeGoal,
            appleStandHoursGoal: appleStandHoursGoal,
            date: date,
            userID: userID
        )
    }
}
