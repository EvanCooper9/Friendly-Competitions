import Firebase
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage
import Resolver
import ResolverAutoregistration

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {

        // Views
        registerViewModels()

        // Managers
        autoregister(ActivitySummaryManaging.self, initializer: ActivitySummaryManager.init)
        autoregister(AnalyticsManaging.self, initializer: AnalyticsManager.init)
        autoregister(AuthenticationManaging.self, initializer: AuthenticationManager.init)
        autoregister(CompetitionsManaging.self, initializer: CompetitionsManager.init)
        autoregister(FriendsManaging.self, initializer: FriendsManager.init)
        autoregister(HealthKitManaging.self, initializer: HealthKitManager.init)
        autoregister(NotificationManaging.self, initializer: NotificationManager.init)
        autoregister(PermissionsManaging.self, initializer: PermissionsManager.init)
        autoregister(StorageManaging.self, initializer: StorageManager.init)
        autoregister(WorkoutManaging.self, initializer: WorkoutManager.init)
        
        // Global state
        register { AppState() }.scope(.shared)

        let environment = UserDefaults.standard.decode(FirestoreEnvironment.self, forKey: "environment") ?? .defaultEnvionment
        registerFirebase(environment: environment)
    }
}

extension Resolver {
    static func registerFirebase(environment: FirestoreEnvironment) {
        register(Firestore.self) {
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
        .scope(.application)

        register(Functions.self) {
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
        .scope(.application)

        register(StorageReference.self) {
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
        .scope(.application)
    }
}
