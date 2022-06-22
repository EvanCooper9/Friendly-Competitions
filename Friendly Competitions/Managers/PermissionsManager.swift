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

    var requiresPermission: AnyPublisher<Bool, Never>
    var permissionStatus: AnyPublisher<[Permission : PermissionStatus], Never> { _permissionStatus.eraseToAnyPublisher() }

    // MARK: - Private Properties

    @Injected private var healthKitManager: HealthKitManaging
    @Injected private var notificationManager: NotificationManaging

    private let _permissionStatus = CurrentValueSubject<[Permission: PermissionStatus], Never>([:])

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init() {
        requiresPermission = _permissionStatus
            .map { statuses in
                statuses.contains { permission, status in
                    status == .notDetermined
                }
            }
            .eraseToAnyPublisher()

        Publishers
            .CombineLatest(healthKitManager.permissionStatus, notificationManager.permissionStatus)
            .map { [.health: $0, .notifications: $1] }
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?._permissionStatus.send($0) }
            .store(in: &cancellables)
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
