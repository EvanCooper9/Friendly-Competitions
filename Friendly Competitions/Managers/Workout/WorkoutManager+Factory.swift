import Factory
import Foundation

extension Container {
    var workoutCache: Factory<WorkoutCache> {
        self { UserDefaults.standard  }.scope(.shared)
    }

    var workoutManager: Factory<WorkoutManaging> {
        self { WorkoutManager() }.scope(.shared)
    }
}
