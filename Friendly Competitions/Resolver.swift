import Firebase
import FirebaseFirestore
import FirebaseStorage
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {

        // Managers
//        register(AnyActivitySummaryManager.self) { ActivitySummaryManager() }.scope(.shared)
        register(AnyActivitySummaryManager.self) {
            let acManager = AnyActivitySummaryManager()
            acManager.activitySummary = .mock
            return acManager
        }.scope(.shared)
        
        register(AnyAnalyticsManager.self) { AnalyticsManager() }.scope(.shared)
        register(AnyAuthenticationManager.self) { AuthenticationManager() }.scope(.application)
        register(AnyCompetitionsManager.self) { CompetitionsManager() }.scope(.shared)
        register(AnyFriendsManager.self) { FriendsManager() }.scope(.shared)
        register(AnyHealthKitManager.self) { HealthKitManager() }.scope(.shared)
        register(NotificationManaging.self) { NotificationManager() }.scope(.shared)
        register(AnyPermissionsManager.self) { PermissionsManager() }.scope(.shared)
        register(AnyStorageManager.self) { StorageManager() }.scope(.shared)
        
        // Global state
        register { AppState() }.scope(.application)

        // Firebase
        register { Firestore.firestore() }.scope(.shared)
        register { Storage.storage().reference() }.scope(.shared)
    }
}
