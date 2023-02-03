import Factory
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage

extension Container {
    
    // Managers
    static let activitySummaryManager = Factory(scope: .shared) { ActivitySummaryManager() as ActivitySummaryManaging }
    static let analyticsManager = Factory(scope: .shared) { AnalyticsManager() as AnalyticsManaging }
    static let authenticationManager = Factory(scope: .shared) { AuthenticationManager() as AuthenticationManaging }
    static let competitionsManager = Factory(scope: .shared) { CompetitionsManager() as CompetitionsManaging }
    static let environmentManager = Factory(scope: .singleton) { EnvironmentManager() as EnvironmentManaging }
    static let friendsManager = Factory(scope: .shared) { FriendsManager() as FriendsManaging }
    static let healthKitManager = Factory(scope: .shared) { HealthKitManager() as HealthKitManaging }
    static let notificationManager = Factory(scope: .shared) { NotificationManager() as NotificationManaging }
    static let permissionsManager = Factory(scope: .shared) { PermissionsManager() as PermissionsManaging }
    static let premiumManager = Factory(scope: .shared) { PremiumManager() as PremiumManaging }
    static let profanityManager = Factory(scope: .shared) { ProfanityManager() as ProfanityManaging }
    static let storageManager = Factory(scope: .shared) { StorageManager() as StorageManaging }
    static let userManager = Factory<UserManaging>(scope: .shared) { fatalError("User manager not initialized") }
    static let workoutManager = Factory(scope: .shared) { WorkoutManager() as WorkoutManaging }
    
    // Global state
    static let appState = Factory(scope: .shared) { AppState() as AppStateProviding }
    
    static let database = Factory(scope: .shared) {
        let environment = Container.environmentManager.callAsFunction().firestoreEnvironment
        let firestore = Firestore.firestore()
        let settings = firestore.settings

        switch environment.type {
        case .prod:
            break
        case .debug:
            settings.isPersistenceEnabled = false
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
        let environment = Container.environmentManager.callAsFunction().firestoreEnvironment
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
        let environment = Container.environmentManager.callAsFunction().firestoreEnvironment
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
