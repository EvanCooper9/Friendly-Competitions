import ECKit
import Factory
import UIKit

final class DeveloperAppService: AppService {

    // Needs to be lazy so that `FirebaseApp.configure()` is called first
    @LazyInjected(\.api) private var api

    private var cancellables = Cancellables()

    func didFinishLaunching() {
        // do nothing
    }
}
