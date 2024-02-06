import HealthKit

extension HKActivitySummary {
    static var mock: HKActivitySummary {
        let summary = HKActivitySummary()
        summary.activeEnergyBurned = .init(unit: .kilocalorie(), doubleValue: 33)
        summary.activeEnergyBurnedGoal = .init(unit: .kilocalorie(), doubleValue: 100)
        summary.appleExerciseTime = .init(unit: .minute(), doubleValue: 57)
        summary.appleExerciseTimeGoal = .init(unit: .minute(), doubleValue: 100)
        summary.appleStandHours = .init(unit: .count(), doubleValue: 8)
        summary.appleStandHoursGoal = .init(unit: .count(), doubleValue: 12)
        return summary
    }

    var activitySummary: ActivitySummary {
        .init(
            activeEnergyBurned: activeEnergyBurned.doubleValue(for: .kilocalorie()).rounded(.down),
            appleExerciseTime: appleExerciseTime.doubleValue(for: .minute()),
            appleStandHours: appleStandHours.doubleValue(for: .count()),
            activeEnergyBurnedGoal: activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()),
            appleExerciseTimeGoal:  appleExerciseTimeGoal.doubleValue(for: .minute()),
            appleStandHoursGoal: appleStandHoursGoal.doubleValue(for: .count()),
            date: Calendar.current.date(from: dateComponents(for: .current)) ?? .now
        )
    }

    var isToday: Bool {
        dateComponents(for: .current).day == Calendar.current.dateComponents([.day], from: Date()).day
    }
}
