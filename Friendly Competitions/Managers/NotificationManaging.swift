import FirebaseFirestore
import FirebaseMessaging
import Resolver
import UserNotifications
import UIKit

protocol NotificationManaging {
    func shouldRequestPermissions(_ completion: @escaping (Bool) -> Void)
    func requestPermissions(_ completion: @escaping (Bool, Error?) -> Void)
}

final class NotificationManager: NSObject, NotificationManaging {

    @LazyInjected private var database: Firestore
    @LazyInjected private var user: User

    override init() {
        super.init()
        Messaging.messaging().delegate = self
    }

    func shouldRequestPermissions(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus == .notDetermined)
        }
    }

    func requestPermissions(_ completion: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { completion($0, $1) }
        )
        UIApplication.shared.registerForRemoteNotifications()
    }
}

extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken, !user.notificationTokens.contains(fcmToken) else { return }
        user.notificationTokens.append(fcmToken)
        try? database.document("users/\(user.id)").setData(["notificationTokens": user.notificationTokens])
    }
}
