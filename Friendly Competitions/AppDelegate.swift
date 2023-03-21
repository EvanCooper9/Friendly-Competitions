import Factory
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    @Injected(\.appServices) private var appServices

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        guard appServices.isNotEmpty else { return true }
        return appServices
            .map { $0.application(application, didFinishLaunchingWithOptions: launchOptions) }
            .allTrue()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        appServices.forEach { $0.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken) }
    }
}
