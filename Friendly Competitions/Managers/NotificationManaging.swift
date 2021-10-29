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
        setupNotifications()
    }

    func shouldRequestPermissions(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            if settings.authorizationStatus == .authorized { self?.setupNotifications() }
            completion(settings.authorizationStatus == .notDetermined)
        }
    }

    func requestPermissions(_ completion: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { [weak self] granted, error in
                if granted { self?.setupNotifications() }
                completion(granted, error)
            }
        )
    }

    private func setupNotifications() {
        DispatchQueue.main.async {
//            Messaging.messaging().delegate = self
            UNUserNotificationCenter.current().delegate = self
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

//extension NotificationManager: MessagingDelegate {
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        guard let fcmToken = fcmToken, !user.notificationTokens.contains(fcmToken) else { return }
//        user.notificationTokens.append(fcmToken)
//        database.document("users/\(user.id)").updateData(["notificationTokens": user.notificationTokens])
//    }
//}

extension NotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // With swizzling disabled you must let Messaging know about the message, for Analytics
//        let userInfo = notification.request.content.userInfo
//        Messaging.messaging().appDidReceiveMessage(userInfo)
        return [.sound, .banner, .badge, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // With swizzling disabled you must let Messaging know about the message, for Analytics
//        let userInfo = response.notification.request.content.userInfo
//        Messaging.messaging().appDidReceiveMessage(userInfo)
    }
}
