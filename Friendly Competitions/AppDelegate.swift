import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Resolver
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    @LazyInjected private var database: Firestore

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
        guard let fcmToken = fcmToken, let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            let user = try await database.document("users/\(userId)")
                .getDocument()
                .decoded(as: User.self)

            print("fcmToken: \(fcmToken)")
            guard user.notificationTokens?.contains(fcmToken) == false else { return }
            user.notificationTokens = user.notificationTokens?.appending(fcmToken) ?? [fcmToken]
            try await database.document("users/\(userId)").updateDataEncodable(user)
        }
    }
}
