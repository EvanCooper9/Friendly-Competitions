import ECKit
import Factory
import FCKit

final class DataUploadingAppService: AppService {

    // Needs to be lazy so that `FirebaseApp.configure()` is called first
    @LazyInjected(\.authenticationManager) private var authenticationManager: AuthenticationManaging
    @LazyInjected(\.healthKitManager) private var healthKitManager: HealthKitManaging

    private var activitySummaryManager: ActivitySummaryManaging?
    private var stepCountManager: StepCountManaging?
    private var workoutManager: WorkoutManaging?

    private var cancellables = Cancellables()

    func didFinishLaunching() {
        // Retain the managers responsible for uploading data so that they are allocated on app launch,
        // regardless if they're being used throughout the app or not. Example: activity summary manager is
        // retained by the home screen, in order to show the latest activity summary. However, the workout
        // manager is only retained by the results screen, so workouts aren't uploaded unless the user visits
        // that screen
        authenticationManager.loggedIn
            .sink(withUnretained: self) { strongSelf, loggedIn in
                if loggedIn {
                    strongSelf.activitySummaryManager = Container.shared.activitySummaryManager.resolve()
                    strongSelf.stepCountManager = Container.shared.stepCountManager.resolve()
                    strongSelf.workoutManager = Container.shared.workoutManager.resolve()
                } else {
                    strongSelf.activitySummaryManager = nil
                    strongSelf.stepCountManager = nil
                    strongSelf.workoutManager = nil
                }
            }
            .store(in: &cancellables)

        healthKitManager.registerForBackgroundDelivery()
    }
}
