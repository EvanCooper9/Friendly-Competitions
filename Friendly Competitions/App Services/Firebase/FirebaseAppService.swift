import Factory
import Firebase
import FirebaseMessaging

final class FirebaseAppService: NSObject, AppService {

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
        guard let fcmToken = fcmToken, let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            let tokens = try await database.document("users/\(userId)")
                .getDocument(as: User.self, source: .cacheFirst)
                .async()
                .notificationTokens ?? []

            guard !tokens.contains(fcmToken) else { return }
            try await database.document("users/\(userId)")
                .updateData(from: ["notificationTokens": tokens.appending(fcmToken)])
                .async()
        }
    }
}
