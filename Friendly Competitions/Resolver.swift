import Firebase
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage
import Resolver

private enum FirebaseEmulation {
    static let enabled = false
    static let host = "192.168.2.92"
}

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {

        // Views
        registerViewModels()

        // Managers
        register(ActivitySummaryManaging.self) { ActivitySummaryManager() }.scope(.shared)
        register(AnalyticsManaging.self) { AnalyticsManager() }.scope(.shared)
        register(AuthenticationManaging.self) { AuthenticationManager() }.scope(.shared)
        register(CompetitionsManaging.self) { CompetitionsManager() }.scope(.shared)
        register(FriendsManaging.self) { FriendsManager(database: resolve(), userManager: resolve()) }.scope(.shared)
        register(HealthKitManaging.self) { HealthKitManager() }.scope(.shared)
        register(NotificationManaging.self) { NotificationManager() }.scope(.shared)
        register(PermissionsManaging.self) { PermissionsManager(healthKitManager: resolve(), notificationManager: resolve()) }.scope(.shared)
        register(StorageManaging.self) { StorageManager() }.scope(.shared)
        register(WorkoutManaging.self) { WorkoutManager() }.scope(.shared)
        
        // Global state
        register { AppState() }.scope(.shared)

        // Firebase
        register(Firestore.self) {
            let firestore = Firestore.firestore()
            let settings = firestore.settings
            settings.isPersistenceEnabled = false
            settings.cacheSizeBytes = 1_048_576 // 1 MB
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
