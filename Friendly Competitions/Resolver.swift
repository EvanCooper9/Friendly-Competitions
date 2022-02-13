import Firebase
import FirebaseFirestore
import Resolver

extension Resolver.Name {
    static let main = Self("main")
    static let mock = Self("mock")
    static var mode: Resolver.Name = .main
}

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {

        register { ActivitySummaryManager() as AnyActivitySummaryManager }.scope(.application)
        register { AuthenticationManager() as AnyAuthenticationManager }.scope(.application)
        register { CompetitionsManager() as AnyCompetitionsManager }.scope(.application)
        register { FriendsManager() as AnyFriendsManager }.scope(.application)
        register { HealthKitManager() as AnyHealthKitManager }.scope(.application)
        register { NotificationManager() as NotificationManaging }.scope(.application)
        register { PermissionsManager() as AnyPermissionsManager }.scope(.application)

        register(Firestore.self) {
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            let database = Firestore.firestore()
            database.settings = settings
            return database
        }
        .scope(.application)
    }
}
