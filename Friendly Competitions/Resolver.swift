import Firebase
import FirebaseFirestore
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { ActivitySummaryManager() as AnyActivitySummaryManager }.scope(.shared)
        register { AuthenticationManager() as AnyAuthenticationManager }.scope(.shared)
        register { CompetitionsManager() as AnyCompetitionsManager }.scope(.shared)
        register { FriendsManager() as AnyFriendsManager }.scope(.shared)
        register { HealthKitManager() as AnyHealthKitManager }.scope(.shared)
        register { NotificationManager() as NotificationManaging }.scope(.shared)
        register { PermissionsManager() as AnyPermissionsManager }.scope(.shared)
        register { Firestore.firestore() }.scope(.shared)
    }
}
