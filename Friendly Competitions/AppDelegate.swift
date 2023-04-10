import Factory
import Foundation
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    @Injected(\.appServices) private var appServices

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        appServices.forEach { $0.didFinishLaunching() }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        appServices.forEach { $0.didRegisterForRemoteNotifications(with: deviceToken) }
    }
}
