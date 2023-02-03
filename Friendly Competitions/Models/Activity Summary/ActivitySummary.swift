import HealthKit

struct ActivitySummary: Identifiable, Codable, Equatable {
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
        case .percentOfGoals:
            return (activeEnergyBurned / activeEnergyBurnedGoal) +
                (appleExerciseTime / appleStandHoursGoal) +
                (appleStandHours / appleStandHoursGoal)
        case .rawNumbers:
            return activeEnergyBurned + appleExerciseTime + appleStandHours
        case .workout:
            return 0
        }
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
