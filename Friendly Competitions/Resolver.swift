import Firebase
import FirebaseAuth
import FirebaseFirestore
import Resolver

extension Resolver.Name {
    static let main = Self("main")
    static let mock = Self("mock")
    static var mode: Resolver.Name = .main
}

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { resolve(name: .mode) as AnyActivitySummaryManager }
        register(name: .main) { ActivitySummaryManager() as AnyActivitySummaryManager }.scope(.application)

        register { resolve(name: .mode) as AnyCompetitionsManager }
        register(name: .main) { CompetitionsManager() as AnyCompetitionsManager }.scope(.application)

        register { resolve(name: .mode) as AnyFriendsManager }
        register(name: .main) { FriendsManager() as AnyFriendsManager }.scope(.application)

        register { resolve(name: .mode) as AnyHealthKitManager }
        register(name: .main) { HealthKitManager() as AnyHealthKitManager }.scope(.application)

        register { resolve(name: .mode) as AnyPermissionsManager }
        register(name: .main) { PermissionsManager() as AnyPermissionsManager }.scope(.application)

        register { resolve(name: .mode) as AnyUserManager }
        register(name: .main) { UserManager() as AnyUserManager }.scope(.application)

        register { resolve(name: .mode) as Firestore }
        register(Firestore.self, name: .main) {
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            let database = Firestore.firestore()
            database.settings = settings
            return database
        }
        .scope(.application)
        register(Firestore.self,name: .mock)  { Firestore.firestore() }

        register { resolve(name: .mode) as NotificationManaging }
        register(name: .main) { NotificationManager() as NotificationManaging }.scope(.application)
        register(name: .mock) { NotificationManager() as NotificationManaging }

        register { resolve(name: .mode) as User }.scope(.application)
        register(name: .mock) { User.evan }
    }
}
