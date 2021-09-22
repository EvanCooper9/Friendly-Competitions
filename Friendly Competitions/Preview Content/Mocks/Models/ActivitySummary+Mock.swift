extension ActivitySummary {
    static var mock: ActivitySummary {
        .init(
            activeEnergyBurned: 100,
            appleExerciseTime: 10,
            appleStandHours: 8,
            activeEnergyBurnedGoal: 300,
            appleExerciseTimeGoal: 20,
            appleStandHoursGoal: 12,
            date: .now
        )
    }
}
