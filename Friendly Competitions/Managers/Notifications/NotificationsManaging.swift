import Combine
import Factory
import UserNotifications
import UIKit

// sourcery: AutoMockable
protocol NotificationsManaging {
    var permissionStatus: AnyPublisher<PermissionStatus, Never> { get }
    func requestPermissions()
}

final class NotificationsManager: NSObject, NotificationsManaging {

    // MARK: - Public Properties

    let permissionStatus: AnyPublisher<PermissionStatus, Never>

    // MARK: - Private Properties
    
    @Injected(\.api) private var api
    @Injected(\.appState) private var appState
    @Injected(\.analyticsManager) private var analyticsManager

    private let _permissionStatus: CurrentValueSubject<PermissionStatus, Never>

    // MARK: - Lifecycle

    override init() {
        _permissionStatus = .init(.done)
        permissionStatus = _permissionStatus.eraseToAnyPublisher()

        super.init()

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async { [weak self] in
                    self?.setupNotifications()
                }
            }
            self._permissionStatus.send(settings.authorizationStatus.permissionStatus)
        }
    }

    // MARK: - Public Methods

    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { [weak self] authorized, error in
                guard let self = self else { return }
                self.analyticsManager.log(event: .notificationPermissions(authorized: authorized))
                if authorized {
                    DispatchQueue.main.async {
                        self.setupNotifications()
                    }
                }
                self._permissionStatus.send(authorized ? .authorized : .denied)
            }
        )
    }

    // MARK: - Private Methods

    private func setupNotifications() {
//        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
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
