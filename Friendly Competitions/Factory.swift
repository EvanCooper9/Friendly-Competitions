import Factory
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage

extension Container {
    
    // Managers
    static let activitySummaryManager = Factory { ActivitySummaryManager() as ActivitySummaryManaging }
    static let analyticsManager = Factory { AnalyticsManager() as AnalyticsManaging }
    static let authenticationManager = Factory { AuthenticationManager() as AuthenticationManaging }
    static let competitionsManager  = Factory { CompetitionsManager() as CompetitionsManaging }
    static let friendsManager  = Factory { FriendsManager() as FriendsManaging }
    static let healthKitManager  = Factory { HealthKitManager() as HealthKitManaging }
    static let notificationManager  = Factory { NotificationManager() as NotificationManaging }
    static let permissionsManager  = Factory { PermissionsManager() as PermissionsManaging }
    static let storageManager  = Factory { StorageManager() as StorageManaging }
    static let workoutManager  = Factory { WorkoutManager() as WorkoutManaging }
    static let userManager = Factory<UserManaging> { fatalError("User manager not initialized") }
    
    // Global state
    static let appState = Factory(scope: .shared) { AppState() }
    
    
    static let database = Factory(scope: .shared) {
        let environment = UserDefaults.standard.decode(FirestoreEnvironment.self, forKey: "environment") ?? .defaultEnvionment
        let firestore = Firestore.firestore()
        let settings = firestore.settings
        settings.isPersistenceEnabled = false
        settings.cacheSizeBytes = 1_048_576 // 1 MB

        switch environment.type {
        case .prod:
            break
        case .debug:
            settings.isSSLEnabled = false
            switch environment.emulationType {
            case .localhost:
                settings.host = "localhost:\(8080)"
            case .custom:
                settings.host = (environment.emulationDestination ?? "localhost") + ":\(8080)"
            }
        }

        firestore.settings = settings
        return firestore
    }
    
    static let functions = Factory(scope: .shared) {
        let environment = UserDefaults.standard.decode(FirestoreEnvironment.self, forKey: "environment") ?? .defaultEnvionment
        let functions = Functions.functions()

        switch environment.type {
        case .prod:
            break
        case .debug:
            switch environment.emulationType {
            case .localhost:
                functions.useEmulator(withHost: "localhost", port: 5001)
            case .custom:
                functions.useEmulator(withHost: environment.emulationDestination ?? "localhost", port: 5001)
            }
        }

        return functions
    }
    
    static let storage = Factory(scope: .shared) {
        let environment = UserDefaults.standard.decode(FirestoreEnvironment.self, forKey: "environment") ?? .defaultEnvionment
        let storage = Storage.storage()

        switch environment.type {
        case .prod:
            break
        case .debug:
            switch environment.emulationType {
            case .localhost:
                storage.useEmulator(withHost: "localhost", port: 9000)
            case .custom:
                storage.useEmulator(withHost: environment.emulationDestination ?? "localhost", port: 9000)
            }
        }

        return storage.reference()
    }
}
