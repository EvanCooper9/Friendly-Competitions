import Combine
import ECKit
import Factory
import FCKit
import Firebase
import FirebaseAppCheck
import FirebaseMessaging

final class FirebaseAppService: NSObject, AppService {

    // Needs to be lazy so that `FirebaseApp.configure()` is called first
    @LazyInjected(\.authenticationManager) private var authenticationManager: AuthenticationManaging
    @LazyInjected(\.database) private var database: Database
    @LazyInjected(\.userManager) private var userManager: UserManaging

    private var cancellables = Cancellables()

    func didFinishLaunching() {
        AppCheck.setAppCheckProviderFactory(FCAppCheckProviderFactory())
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }

    func didRegisterForRemoteNotifications(with deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func didReceiveRemoteNotification(with data: [AnyHashable : Any]) -> AnyPublisher<Void, Never> {
        Messaging.messaging().appDidReceiveMessage(data)
        return .just(())
    }
}

extension FirebaseAppService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        authenticationManager.loggedIn
            .filter { $0 }
            .mapToVoid()
            .compactMap { [weak self] _ -> User? in
                guard let user = self?.userManager.user,
                      user.notificationTokens?.contains(fcmToken) != true else { return nil }
                return user
            }
            .flatMapLatest(withUnretained: self) { strongSelf, user in
                let tokens = user.notificationTokens ?? []
                return strongSelf.database
                    .document("users/\(user.id)")
                    .update(fields: ["notificationTokens": tokens.appending(fcmToken)])
            }
            .first()
            .sink()
            .store(in: &cancellables)
    }
}
