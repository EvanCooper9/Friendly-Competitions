import HealthKit

struct ActivitySummary: Identifiable, Codable, Equatable, Hashable {
    var id: String { date.encodedToString(with: .dateDashed) }

    let activeEnergyBurned: Double
    let appleExerciseTime: Double
    let appleStandHours: Double
    let activeEnergyBurnedGoal: Double
    let appleExerciseTimeGoal: Double
    let appleStandHoursGoal: Double
    let date: Date
    var userID: User.ID?

    var closed: Bool {
        activeEnergyBurned >= activeEnergyBurnedGoal &&
        appleExerciseTime >= appleExerciseTimeGoal &&
        appleStandHours >= appleStandHoursGoal
    }

    func points(from scoringModel: Competition.ScoringModel) -> Double {
        switch scoringModel {
        case .activityRingCloseCount:
            let count = [
                activeEnergyBurned > activeEnergyBurnedGoal,
                appleExerciseTime > appleExerciseTimeGoal,
                appleStandHours > appleStandHoursGoal
            ]
            .filter { $0 }
            .count
            return Double(count)
        case .percentOfGoals:
            return (activeEnergyBurned / activeEnergyBurnedGoal) * 100 +
                (appleExerciseTime / appleStandHoursGoal) * 100 +
                (appleStandHours / appleStandHoursGoal) * 100
        case .rawNumbers:
            return activeEnergyBurned + appleExerciseTime + appleStandHours
        case .stepCount, .workout:
            return 0
        }
    }

    func with(userID: User.ID) -> ActivitySummary {
        var activitySummary = self
        activitySummary.userID = userID
        return activitySummary
    }
}

extension ActivitySummary {
    var hkActivitySummary: HKActivitySummary {
        let summary = HKActivitySummary()
        summary.activeEnergyBurned = .init(unit: .kilocalorie(), doubleValue: activeEnergyBurned)
        summary.activeEnergyBurnedGoal = .init(unit: .kilocalorie(), doubleValue: activeEnergyBurnedGoal)
        summary.appleExerciseTime = .init(unit: .minute(), doubleValue: appleExerciseTime)
        summary.appleExerciseTimeGoal = .init(unit: .minute(), doubleValue: appleExerciseTimeGoal)
        summary.appleStandHours = .init(unit: .count(), doubleValue: appleStandHours)
        summary.appleStandHoursGoal = .init(unit: .count(), doubleValue: appleStandHoursGoal)
        return summary
    }
}
