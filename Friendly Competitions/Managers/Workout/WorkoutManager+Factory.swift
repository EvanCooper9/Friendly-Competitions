import Factory
import Foundation

extension Container {
    var workoutManager: Factory<WorkoutManaging> {
        self { WorkoutManager() }.scope(.shared)
    }
}
