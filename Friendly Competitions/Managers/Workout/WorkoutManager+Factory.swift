import Factory
import Foundation

extension Container {
    var workoutCache: Factory<WorkoutCache> {
        Factory(self) { UserDefaults.standard  }.scope(.shared)
    }
    
    var workoutManager: Factory<WorkoutManaging> {
        Factory(self) { WorkoutManager() }.scope(.shared)
    }
}
