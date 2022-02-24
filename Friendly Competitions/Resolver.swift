import Firebase
import FirebaseFirestore
import FirebaseStorage
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {

        // Managers
        register(AnyActivitySummaryManager.self) { ActivitySummaryManager() }.scope(.shared)
        register(AnyAuthenticationManager.self) { AuthenticationManager() }.scope(.shared)
        register(AnyCompetitionsManager.self) { CompetitionsManager() }.scope(.shared)
        register(AnyFriendsManager.self) { FriendsManager() }.scope(.shared)
        register(AnyHealthKitManager.self) { HealthKitManager() }.scope(.shared)
        register(NotificationManaging.self) { NotificationManager() }.scope(.shared)
        register(AnyPermissionsManager.self) { PermissionsManager() }.scope(.shared)
        register(AnyStorageManager.self) { StorageManager() }.scope(.shared)

        // Firebase
        register { Firestore.firestore() }.scope(.shared)
        register { Storage.storage().reference() }.scope(.shared)
    }
}
