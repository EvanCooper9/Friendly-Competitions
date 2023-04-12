import Factory
import UIKit

final class FeatureFlagAppService: AppService {

    // Needs to be lazy so that `FirebaseApp.configure()` is called first
    @LazyInjected(\.featureFlagManager) private var featureFlagManager

    func didFinishLaunching() {
        featureFlagManager.activate()
    }
}
