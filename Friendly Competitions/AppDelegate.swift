import ECKit_Firebase
import Factory
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import RevenueCat
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    // Needs to be lazy so that `FirebaseApp.configure()` is called first
    @LazyInjected(Container.database) private var database

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        let apiKey: String
        #if DEBUG
        apiKey = "appl_REFBiyXbqcpKtUtawSUJezooOfQ"
        #else
        apiKey = "appl_PfCzNKLwrBPhZHDqVcrFOfigEHq"
        #endif
        Purchases.logLevel = .warn
        Purchases.configure(with: .init(withAPIKey: apiKey).with(usesStoreKit2IfAvailable: true))
        
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {
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
