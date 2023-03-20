import Combine
import CombineExt
import Factory

final class PermissionsViewModel: ObservableObject {
        
    @Published private(set) var permissionStatuses = [(Permission, PermissionStatus)]()

    @Injected(Container.permissionsManager) private var permissionsManager

    init() {
        permissionsManager.permissionStatus
            .map { statuses in
                statuses
                    .map { ($0, $1) }
                    .sorted(by: \.0.rawValue)
            }
            .assign(to: &$permissionStatuses)
    }
    
    func request(_ permission: Permission) {
        permissionsManager.request(permission)
    }
}
