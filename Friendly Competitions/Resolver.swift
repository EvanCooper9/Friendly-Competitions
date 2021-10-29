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
        register { resolve(name: .mode) as ActivitySummaryManaging }
        register(name: .main) { ActivitySummaryManager() as ActivitySummaryManaging }
            .scope(.application)
        register(name: .mock) { MockActivitySummaryManager() as ActivitySummaryManaging }

        register { resolve(name: .mode) as ContactsManaging }
        register(name: .main) { ContactsManager() as ContactsManaging }
        register(name: .mock) { MockContactsManager() as ContactsManaging }

        register { resolve(name: .mode) as HealthKitManaging }
        register(name: .main) { HealthKitManager() as HealthKitManaging }
            .scope(.application)
        register(name: .mock) { HealthKitManager() as HealthKitManaging }

        register { resolve(name: .mode) as Firestore }
        register(Firestore.self, name: .main) {
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            let database = Firestore.firestore()
            database.settings = settings
            return database
        }
        .scope(.application)
        register(Firestore.self,name: .mock)  {
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            let database = Firestore.firestore()
            database.settings = settings
            return database
        }

        register { resolve(name: .mode) as NotificationManaging }
        register(name: .main) { NotificationManager() as NotificationManaging }
            .scope(.application)
        register(name: .mock) { NotificationManager() as NotificationManaging }

        register { resolve(name: .mode) as User }
            .scope(.application)
        if let firebaseUser = Auth.auth().currentUser {
            register(name: .main) {
                User(id: firebaseUser.uid, email: firebaseUser.email ?? "", name: firebaseUser.displayName ?? "")
            }
        }
        register(name: .mock) { User.mock }
    }
}
