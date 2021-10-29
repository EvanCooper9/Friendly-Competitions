import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Resolver

@main
struct FriendlyCompetitionsApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var appModel: AppModel

    init() {
        FirebaseApp.configure()
        appModel = .init()
    }

    var body: some Scene {
        WindowGroup {
            if appModel.loading {
                ProgressView().progressViewStyle(.circular)
            } else if let user = appModel.currentUser {
                HomeView().environmentObject(user)
            } else {
                SignInView()
            }
        }
    }
}

@MainActor
private final class AppModel: ObservableObject {

    @Published var loading = true
    @Published var currentUser: User?

    @LazyInjected private var activitySummaryManager: ActivitySummaryManaging
    @LazyInjected private var database: Firestore
    @LazyInjected private var healthKitManager: HealthKitManaging

    init() {
        if let firebaseUser = Auth.auth().currentUser {
            Resolver.register { User(id: firebaseUser.uid, email: firebaseUser.email ?? "", name: firebaseUser.displayName ?? "") }
            activitySummaryManager.registerForBackgroundDelivery()
            healthKitManager.registerForBackgroundDelivery()
        }

        Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            guard let self = self else { return }

            guard let firebaseUser = firebaseUser else {
                self.currentUser = nil
                self.loading = false
                return
            }

            self.healthKitManager.registerForBackgroundDelivery()

            Task {
                let user = try? await self.database.document("users/\(firebaseUser.uid)")
                    .getDocument()
                    .decoded(as: User.self)

                DispatchQueue.main.async {
                    Resolver.register { user }
                    self.loading = false
                    self.currentUser = user
                }
            }
        }
    }
}
