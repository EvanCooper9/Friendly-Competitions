import Resolver
import UserNotifications
import UIKit

protocol NotificationManaging {
    func permissionStatus(_ completion: @escaping (PermissionStatus) -> Void)
    func requestPermissions(_ completion: @escaping (PermissionStatus) -> Void)
}

final class NotificationManager: NSObject, NotificationManaging {
    
    @Injected private var analyticsManager: AnyAnalyticsManager

    override init() {
        super.init()
        setupNotifications()
    }

    func permissionStatus(_ completion: @escaping (PermissionStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async { [weak self] in
                    self?.setupNotifications()
                }
            }
            completion(settings.authorizationStatus.permissionStatus)
        }
    }

    func requestPermissions(_ completion: @escaping (PermissionStatus) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { [weak self] authorized, error in
                guard let self = self else { return }
                self.analyticsManager.log(event: .healthKitPermissions(authorized: authorized))
                if authorized {
                    DispatchQueue.main.async {
                        self.setupNotifications()
                    }
                }
                self.permissionStatus { completion($0) }
            }
        )
    }

    private func setupNotifications() {
//        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.sound, .banner, .badge, .list]
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
