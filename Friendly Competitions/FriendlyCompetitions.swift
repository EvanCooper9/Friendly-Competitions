import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Resolver

var isPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }

@main
struct FriendlyCompetitions: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var activitySummaryManager = Resolver.resolve(AnyActivitySummaryManager.self)
    @StateObject private var competitionsManager = Resolver.resolve(AnyCompetitionsManager.self)
    @StateObject private var friendsManager = Resolver.resolve(AnyFriendsManager.self)
    @StateObject private var healthKitManager = Resolver.resolve(AnyHealthKitManager.self)
    @StateObject private var permissionsManager = Resolver.resolve(AnyPermissionsManager.self)
    @StateObject private var userManager = Resolver.resolve(AnyUserManager.self)
    @StateObject private var appModel = AppModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if let user = appModel.currentUser {
                Home()
                    .environmentObject(user)
                    .environmentObject(activitySummaryManager)
                    .environmentObject(competitionsManager)
                    .environmentObject(friendsManager)
                    .environmentObject(permissionsManager)
                    .environmentObject(userManager)
            } else {
                SignInView()
            }
        }
    }
}

private final class AppModel: ObservableObject {

    @Published(storedWithKey: "currentUser") var currentUser: User? = nil {
        didSet { setupManagers() }
    }

    private var userListener: ListenerRegistration? {
        willSet { userListener?.remove() }
    }

    @LazyInjected private var activitySummaryManager: AnyActivitySummaryManager
    @LazyInjected private var competitionsManager: AnyCompetitionsManager
    @LazyInjected private var friendsManager: AnyFriendsManager
    @LazyInjected private var database: Firestore
    @LazyInjected private var healthKitManager: AnyHealthKitManager

    init() {
        if let user = currentUser {
            Resolver.register { user }
        }

        setupManagers()
        listenForAuth()
    }

    private func setupManagers() {
        guard let user = currentUser else { return }
        activitySummaryManager.setup(with: user)
        competitionsManager.setup(with: user)
        friendsManager.setup(with: user)
    }

    private func listenForAuth() {
        Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            guard let self = self else { return }

            guard firebaseUser != nil else {
                self.currentUser = nil
                self.userListener = nil
                return
            }

            self.listenForUser()
        }
    }

    private func listenForUser() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        userListener = database.document("users/\(userId)")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let user = try? snapshot?.decoded(as: User.self) else { return }
                DispatchQueue.main.async {
                    Resolver.register { user }
                    self.currentUser = user
                }
            }
    }
}
