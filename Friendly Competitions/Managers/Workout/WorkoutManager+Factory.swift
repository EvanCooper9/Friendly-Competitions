import Factory
import Foundation

extension Container {
    static let workoutManager = Factory<WorkoutManaging>(scope: .shared, factory: WorkoutManager.init)
    static let workoutCache = Factory<WorkoutCache>(scope: .shared) { UserDefaults.standard }
}
