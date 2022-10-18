import Combine
import ECKit
import Factory
import Foundation

// sourcery: AutoMockable
protocol PermissionsManaging {
    var requiresPermission: AnyPublisher<Bool, Never> { get }
    var permissionStatus: AnyPublisher<[Permission: PermissionStatus], Never> { get }
    func request(_ permission: Permission)
}

final class PermissionsManager: PermissionsManaging {

    // MARK: - Public Properties

    let requiresPermission: AnyPublisher<Bool, Never>
    let permissionStatus: AnyPublisher<[Permission: PermissionStatus], Never>

    // MARK: - Private Properties

    @Injected(Container.healthKitManager) private var healthKitManager
    @Injected(Container.notificationManager) private var notificationManager
    
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        let permissionStatusSubject = PassthroughSubject<[Permission: PermissionStatus], Never>()
        
        permissionStatus = permissionStatusSubject
            .receive(on: RunLoop.main)
            .share(replay: 1)
            .eraseToAnyPublisher()
        
        requiresPermission = permissionStatus
            .map { statuses in
                statuses.contains { permission, status in
                    status == .notDetermined
                }
            }
            .eraseToAnyPublisher()
        
        Publishers
            .CombineLatest(healthKitManager.permissionStatus, notificationManager.permissionStatus)
            .map { [.health: $0, .notifications: $1] }
            .sink { permissionStatusSubject.send($0) }
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
