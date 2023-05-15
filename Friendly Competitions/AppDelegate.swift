import Combine
import ECKit
import Factory
import Foundation
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    @Injected(\.appServices) private var appServices

    private var cancellables = Cancellables()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        appServices.forEach { $0.didFinishLaunching() }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        appServices.forEach { $0.didRegisterForRemoteNotifications(with: deviceToken) }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        appServices.map { $0.didReceiveRemoteNotification(with: userInfo) }
            .combineLatest()
            .first()
            .mapToVoid()
            .sink { completionHandler(.newData) }
            .store(in: &cancellables)
    }
}
