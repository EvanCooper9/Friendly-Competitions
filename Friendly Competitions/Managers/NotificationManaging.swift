import FirebaseFirestore
import FirebaseMessaging
import Resolver
import UserNotifications
import UIKit

protocol NotificationManaging {
    func permissionStatus(_ completion: @escaping (PermissionStatus) -> Void)
    func requestPermissions(_ completion: @escaping (PermissionStatus) -> Void)
}

final class NotificationManager: NSObject, NotificationManaging {

    @LazyInjected private var database: Firestore
    @LazyInjected private var user: User

    override init() {
        super.init()
        setupNotifications()
    }

    func permissionStatus(_ completion: @escaping (PermissionStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            if settings.authorizationStatus == .authorized { self?.setupNotifications() }
            completion(settings.authorizationStatus.permissionStatus)
        }
    }

    func requestPermissions(_ completion: @escaping (PermissionStatus) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { [weak self] granted, error in
                guard let self = self else { return }
                if granted { self.setupNotifications() }
                self.permissionStatus { completion($0) }
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

extension UNAuthorizationStatus {
    var permissionStatus: PermissionStatus {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
}
