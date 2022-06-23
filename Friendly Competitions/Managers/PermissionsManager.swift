import Combine
import Foundation
import Resolver

// sourcery: AutoMockable
protocol PermissionsManaging {
    var requiresPermission: AnyPublisher<Bool, Never> { get }
    var permissionStatus: AnyPublisher<[Permission: PermissionStatus], Never> { get }
    func request(_ permission: Permission)
}

final class PermissionsManager: PermissionsManaging {

    // MARK: - Public Properties

    let requiresPermission: AnyPublisher<Bool, Never>
    let permissionStatus: AnyPublisher<[Permission : PermissionStatus], Never>

    // MARK: - Private Properties

    private let healthKitManager: HealthKitManaging
    private let notificationManager: NotificationManaging

    // MARK: - Lifecycle

    init(healthKitManager: HealthKitManaging, notificationManager: NotificationManaging) {
        self.healthKitManager = healthKitManager
        self.notificationManager = notificationManager

        permissionStatus = Publishers
            .CombineLatest(healthKitManager.permissionStatus, notificationManager.permissionStatus)
            .map { [.health: $0, .notifications: $1] }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()

        requiresPermission = permissionStatus
            .map { statuses in
                statuses.contains { permission, status in
                    status == .notDetermined
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Public Methods

    func request(_ permission: Permission) {
        switch permission {
        case .health:
            healthKitManager.requestPermissions()
        case .notifications:
            notificationManager.requestPermissions()
        }
    }
}
