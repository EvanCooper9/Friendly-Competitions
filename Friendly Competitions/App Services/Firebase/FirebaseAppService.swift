import Factory
import Firebase
import FirebaseMessaging

final class FirebaseAppService: NSObject, AppService {
    
    // Needs to be lazy so that `FirebaseApp.configure()` is called first
    @LazyInjected(\.database) private var database
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension FirebaseAppService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken, let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            let tokens = try await database.document("users/\(userId)")
                .getDocument(as: User.self) // TODO: fetch from cache sources
                .async()
                .notificationTokens ?? []

            guard !tokens.contains(fcmToken) else { return }
            try await database.document("users/\(userId)")
                .updateData(from: ["notificationTokens": tokens.appending(fcmToken)])
                .async()
        }
    }
}
