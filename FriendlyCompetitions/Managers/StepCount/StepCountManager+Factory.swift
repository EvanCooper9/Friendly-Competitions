import Factory

extension Container {
    var stepCountManager: Factory<StepCountManaging> {
        self { StepCountManager() }.scope(.shared)
    }
}
