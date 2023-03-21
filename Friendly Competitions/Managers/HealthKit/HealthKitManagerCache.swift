import Foundation

// sourcery: AutoMockable
protocol HealthKitManagerCache {
    var permissionStatus: [HealthKitPermissionType: PermissionStatus] { get set }
}

extension UserDefaults: HealthKitManagerCache {

    private enum Constants {
        static let permissionStatusKey = "health_kit_permissions"
    }

    var permissionStatus: [HealthKitPermissionType : PermissionStatus] {
        get { decode([HealthKitPermissionType : PermissionStatus].self, forKey: Constants.permissionStatusKey) ?? [:] }
        set { encode(newValue, forKey: Constants.permissionStatusKey) }
    }
}
