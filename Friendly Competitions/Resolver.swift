import Firebase
import FirebaseFirestore
import FirebaseStorage
import Resolver

private enum FirebaseEmulation {
    static let enabled = false
    static let host = "localhost"
}

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {

        // Managers
        register(AnyActivitySummaryManager.self) { ActivitySummaryManager() }.scope(.shared)
        register(AnyAnalyticsManager.self) { AnalyticsManager() }.scope(.shared)
        register(AnyAuthenticationManager.self) { AuthenticationManager() }.scope(.shared)
        register(CompetitionsManaging.self) { CompetitionsManager() }.scope(.shared)
        register(AnyFriendsManager.self) { FriendsManager() }.scope(.shared)
        register(AnyHealthKitManager.self) { HealthKitManager() }.scope(.shared)
        register(NotificationManaging.self) { NotificationManager() }.scope(.shared)
        register(AnyPermissionsManager.self) { PermissionsManager() }.scope(.shared)
        register(AnyStorageManager.self) { StorageManager() }.scope(.shared)
        register(AnyWorkoutManager.self) { WorkoutManager() }.scope(.shared)
        
        // Global state
        register { AppState() }.scope(.shared)

        // Firebase
        register(Firestore.self) {
            let firestore = Firestore.firestore()
            let settings = firestore.settings
            settings.isPersistenceEnabled = false
            if FirebaseEmulation.enabled {
                settings.host = "\(FirebaseEmulation.host):8080"
                settings.isSSLEnabled = false
            }
            firestore.settings = settings
            return firestore
        }
        .scope(.application)
        
        register(Functions.self) {
            let functions = Functions.functions()
            if FirebaseEmulation.enabled {
                functions.useEmulator(withHost: FirebaseEmulation.host, port: 5001)
            }
            return functions
        }
        .scope(.application)
        
        register(StorageReference.self) {
            let storage = Storage.storage()
//            if FirebaseEmulation.enabled {
//                storage.useEmulator(withHost: FirebaseEmulation.host, port: 9199)
//            }
            return storage.reference()
        }
        .scope(.application)
    }
}
