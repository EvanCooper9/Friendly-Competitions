import Combine
import Factory
import UserNotifications
import UIKit

// sourcery: AutoMockable
protocol NotificationManaging {
    var permissionStatus: AnyPublisher<PermissionStatus, Never> { get }
    func requestPermissions()
}

final class NotificationManager: NSObject, NotificationManaging {

    // MARK: - Public Properties

    let permissionStatus: AnyPublisher<PermissionStatus, Never>

    // MARK: - Private Properties
    
    @LazyInjected(Container.analyticsManager) private var analyticsManager

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

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.sound, .banner, .badge, .list]
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
