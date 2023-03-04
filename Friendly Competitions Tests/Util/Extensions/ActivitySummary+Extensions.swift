import Foundation

@testable import Friendly_Competitions

extension ActivitySummary {
    func with(userID: User.ID) -> ActivitySummary {
        var activitySummary = self
        activitySummary.userID = userID
        return activitySummary
    }
    
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
