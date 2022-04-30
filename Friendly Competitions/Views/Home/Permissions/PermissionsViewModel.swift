import Combine
import CombineExt
import Resolver

final class PermissionsViewModel: ObservableObject {
        
    @Published private(set) var permissionStatuses = [(Permission, PermissionStatus)]()
    
    @Injected private var permissionsManager: AnyPermissionsManager
    
    init() {
        permissionsManager.$permissionStatus
            .map { statuses in
                statuses.map { ($0, $1) }
            }
            .assign(to: &$permissionStatuses)
    }
    
    func request(_ permission: Permission) {
        permissionsManager.request(permission)
    }
}
