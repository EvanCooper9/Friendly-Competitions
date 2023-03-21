import Combine
import CombineExt
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

    var requiresPermission: AnyPublisher<Bool, Never> {
        permissionStatus
            .map { $0.map(\.value).contains(.notDetermined) }
            .receive(on: scheduler)
            .eraseToAnyPublisher()
    }

    var permissionStatus: AnyPublisher<[Permission: PermissionStatus], Never> {
        permissionStatusSubject
            .receive(on: scheduler)
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    @Injected(\.healthKitManager) private var healthKitManager
    @Injected(\.notificationsManager) private var notificationManager
    @Injected(\.scheduler) private var scheduler

    private let permissionStatusSubject = ReplaySubject<[Permission: PermissionStatus], Never>(bufferSize: 1)

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        Publishers
            .CombineLatest(healthKitManager.permissionStatus, notificationManager.permissionStatus)
            .map { [.health: $0, .notifications: $1] }
            .sink(withUnretained: self) { $0.permissionStatusSubject.send($1) }
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
