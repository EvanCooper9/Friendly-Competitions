#if DEBUG
import Foundation

extension Workout {
    static func mock(type: WorkoutType = .walking, date: Date = .now, points: [WorkoutMetric: Int] = [:]) -> Workout {
        .init(
            type: type,
            date: date,
            points: points
        )
    }
}
#endif
