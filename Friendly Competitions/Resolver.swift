import Firebase
import FirebaseFirestore
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { ActivitySummaryManager() as AnyActivitySummaryManager }.scope(.application)
        register { AuthenticationManager() as AnyAuthenticationManager }.scope(.application)
        register { CompetitionsManager() as AnyCompetitionsManager }.scope(.application)
        register { FriendsManager() as AnyFriendsManager }.scope(.application)
        register { HealthKitManager() as AnyHealthKitManager }.scope(.application)
        register { NotificationManager() as NotificationManaging }.scope(.application)
        register { PermissionsManager() as AnyPermissionsManager }.scope(.application)
        register { Firestore.firestore() }.scope(.application)
    }
}
