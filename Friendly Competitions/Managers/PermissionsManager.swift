import Combine
import Foundation
import Resolver

class AnyPermissionsManager: ObservableObject {
    @Published var requiresPermission = false
    @Published var permissionStatus = [Permission: PermissionStatus]()
    func request(_ permission: Permission) { }
}

final class PermissionsManager: AnyPermissionsManager {

    // MARK: - Public Properties

    override var permissionStatus: [Permission: PermissionStatus] {
        didSet {
            updateRequiresPermission()
        }
    }

    // MARK: - Private Properties

    @Injected private var healthKitManager: AnyHealthKitManager
    @Injected private var notificationManager: NotificationManaging

    // MARK: - Lifecycle

    override init() {
        super.init()
        permissionStatus = [
            .health: healthKitManager.permissionStatus
            /// don't set .notifications to not accidentally show permissions modal on launch,
            /// since it needs to be fetched with a callback
        ]

        notificationManager.permissionStatus { [weak self] permissionStatus in
            DispatchQueue.main.async {
                self?.permissionStatus[.notifications] = permissionStatus
                self?.updateRequiresPermission()
            }
        }
    }

    // MARK: - Public Methods

    override func request(_ permission: Permission) {
        switch permission {
        case .health:
            healthKitManager.requestPermissions { [weak self] permissionStatus in
                self?.updateRequestedPermission(permission, permissionStatus)
            }
        case .notifications:
            notificationManager.requestPermissions { [weak self] permissionStatus in
                self?.updateRequestedPermission(permission, permissionStatus)
            }
        }
    }

    // MARK: - Private Methods

    private func updateRequestedPermission(_ permission: Permission, _ permissionStatus: PermissionStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.permissionStatus[permission] = permissionStatus
        }
    }

    private func updateRequiresPermission() {
        requiresPermission = permissionStatus.contains { _, status in
            status == .notDetermined
        }
    }
}
