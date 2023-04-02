import Factory
import Firebase
import FirebaseMessaging

final class FirebaseAppService: NSObject, AppService {

    @LazyInjected(\.auth) private var auth
    @LazyInjected(\.userManager) private var userManager
    // Needs to be lazy so that `FirebaseApp.configure()` is called first
    @LazyInjected(\.database) private var database

    func didFinishLaunching() {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }

    func didRegisterForRemoteNotifications(with deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension FirebaseAppService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken, let userId = auth.user?.id else { return }

        Task {
            let tokens = try await database.document("users/\(userId)")
                .get(as: User.self, source: .cacheFirst)
                .async()
                .notificationTokens ?? []

            guard !tokens.contains(fcmToken) else { return }
            try await database.document("users/\(userId)")
                .update(fields: ["notificationTokens": tokens.appending(fcmToken)])
                .async()
        }
    }
}
