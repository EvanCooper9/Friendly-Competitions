import Foundation

// sourcery: AutoMockable
protocol WorkoutCache {
    var workouts: [Workout.ID: Workout] { get set }
    var workoutMetrics: [WorkoutType: [WorkoutMetric]] { get set }
}

extension UserDefaults: WorkoutCache {

    private enum Constants {
        static var workoutsKey: String { #function }
        static var workoutMetricsKey: String { #function }
    }

    var workouts: [Workout.ID: Workout] {
        get { decode([Workout.ID: Workout].self, forKey: Constants.workoutsKey) ?? [:] }
        set { encode(newValue, forKey: Constants.workoutsKey) }
    }

    var workoutMetrics: [WorkoutType : [WorkoutMetric]] {
        get { decode([WorkoutType: [WorkoutMetric]].self, forKey: Constants.workoutMetricsKey) ?? [:] }
        set { encode(newValue, forKey: Constants.workoutMetricsKey) }
    }
}
