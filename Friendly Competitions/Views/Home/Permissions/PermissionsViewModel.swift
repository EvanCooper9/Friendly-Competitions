import Combine
import Foundation
import Resolver

final class PermissionsViewModel: ObservableObject {

    @Published var permissionStatus = [Permission: PermissionStatus]()

    @LazyInjected private var contactsManager: ContactsManaging
    @LazyInjected private var healthKitManager: AnyHealthKitManager
    @LazyInjected private var notificationManager: NotificationManaging

    init() {
        permissionStatus = [
            .health: healthKitManager.permissionStatus,
            .notifications: .notDetermined,
            .contacts: contactsManager.permissionStatus
        ]

        notificationManager.permissionStatus { [weak self] permissionStatus in
            DispatchQueue.main.async {
                self?.permissionStatus[.notifications] = permissionStatus
            }
        }
    }

    func request(_ permission: Permission) {
        switch permission {
        case .health:
            healthKitManager.requestPermissions { [weak self] permissionStatus in
                self?.updateRequestedPermission(permission, permissionStatus)
            }
        case .notifications:
            notificationManager.requestPermissions { [weak self] permissionStatus in
                self?.updateRequestedPermission(permission, permissionStatus)
            }
        case .contacts:
            contactsManager.requestPermissions { [weak self] permissionStatus in
                self?.updateRequestedPermission(permission, permissionStatus)
            }
        }
    }

    private func updateRequestedPermission(_ permission: Permission, _ permissionStatus: PermissionStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.permissionStatus[permission] = permissionStatus
        }
    }
}
