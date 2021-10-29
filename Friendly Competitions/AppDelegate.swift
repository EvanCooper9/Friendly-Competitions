import FirebaseFirestore
import FirebaseMessaging
import Resolver
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    @LazyInjected private var database: Firestore
    @LazyInjected private var user: User

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Messaging.messaging().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken, !user.notificationTokens.contains(fcmToken) else { return }
        user.notificationTokens.append(fcmToken)
        database.document("users/\(user.id)").updateData(["notificationTokens": user.notificationTokens])
    }
}
