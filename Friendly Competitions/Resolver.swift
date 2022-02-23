import Firebase
import FirebaseFirestore
import FirebaseStorage
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { ActivitySummaryManager() as AnyActivitySummaryManager }.scope(.shared)
        register { AuthenticationManager() as AnyAuthenticationManager }.scope(.shared)

//        register { CompetitionsManager() as AnyCompetitionsManager }.scope(.shared)
        register(AnyCompetitionsManager.self) { MockCompetitionManager() }.scope(.application)

//        register { FriendsManager() as AnyFriendsManager }.scope(.shared)
        register(AnyFriendsManager.self) { MockFriendsManager() }.scope(.shared)

        register { HealthKitManager() as AnyHealthKitManager }.scope(.shared)
        register { NotificationManager() as NotificationManaging }.scope(.shared)
        register { PermissionsManager() as AnyPermissionsManager }.scope(.shared)
        register { StorageManager() as AnyStorageManager }.scope(.shared)
        register { Firestore.firestore() }.scope(.shared)
        register { Storage.storage().reference() }.scope(.shared)
    }
}
