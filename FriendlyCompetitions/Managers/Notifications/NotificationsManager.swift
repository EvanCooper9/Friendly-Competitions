import Combine
import Factory
import UserNotifications
import UIKit

// sourcery: AutoMockable
protocol NotificationsManaging {
    func setUp()
    func permissionStatus() -> AnyPublisher<PermissionStatus, Never>
    func requestPermissions() -> AnyPublisher<Bool, Error>
}

final class NotificationsManager: NSObject, NotificationsManaging {

    // MARK: - Private Properties

    @Injected(\.appState) private var appState
    @Injected(\.analyticsManager) private var analyticsManager

    // MARK: - Public Methods

    func setUp() {
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }

    func permissionStatus() -> AnyPublisher<PermissionStatus, Never> {
        Future { promise in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                promise(.success(settings.authorizationStatus.permissionStatus))
            }
        }
        .eraseToAnyPublisher()
    }

    func requestPermissions() -> AnyPublisher<Bool, Error> {
        Future { promise in
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound],
                completionHandler: { [weak self] authorized, error in
                    guard let self else { return }
                    self.analyticsManager.log(event: .notificationPermissions(authorized: authorized))
                    if let error {
                        promise(.failure(error))
                    } else {
                        promise(.success(authorized))
                    }
                }
            )
        }
        .eraseToAnyPublisher()
    }
}

extension NotificationsManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.sound, .banner, .badge, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            defer { completionHandler() }
            guard let link = response.notification.request.content.userInfo["link"] as? String,
                  let url = URL(string: link),
                  let deepLink = DeepLink(from: url)
            else { return }
            self?.appState.push(deepLink: deepLink)
        }
    }
}

private extension UNAuthorizationStatus {
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
