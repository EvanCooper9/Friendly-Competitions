import Factory
import UIKit

final class FeatureFlagAppService: AppService {

    // Needs to be lazy so that `FirebaseApp.configure()` is called first
    @LazyInjected(\.featureFlagManager) private var featureFlagManager

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {

        // Activate feature flag manager on app launch so that values are ready for consumption
        featureFlagManager.activate()

        return true
    }
}
