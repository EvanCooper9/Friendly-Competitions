import Foundation

// sourcery: AutoMockable
protocol WorkoutCache {
    var workoutMetrics: [WorkoutType: [WorkoutMetric]] { get set }
}

extension UserDefaults: WorkoutCache {
    
    private enum Constants {
        static var workoutMetricsKey: String { #function }
    }
    
    var workoutMetrics: [WorkoutType : [WorkoutMetric]] {
        get { decode([WorkoutType: [WorkoutMetric]].self, forKey: Constants.workoutMetricsKey) ?? [:] }
        set { encode(newValue, forKey: Constants.workoutMetricsKey) }
    }
}
