import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Resolver

@main
struct FriendlyCompetitions: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var appModel: AppModel
    @StateObject private var activitySummaryManager: AnyActivitySummaryManager = ActivitySummaryManager()
    @StateObject private var competitionsManager: AnyCompetitionsManager = CompetitionsManager()
    @StateObject private var healthKitManager: AnyHealthKitManager = HealthKitManager()

    init() {
        FirebaseApp.configure()
        appModel = .init()
    }

    var body: some Scene {
        WindowGroup {
            if appModel.loading {
                ProgressView().progressViewStyle(.circular)
            } else if let user = appModel.currentUser {
                HomeView()
                    .environmentObject(user)
                    .environmentObject(activitySummaryManager)
                    .environmentObject(competitionsManager)
                    .onAppear {
                        competitionsManager.listen()
                    }
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

    private var userListener: ListenerRegistration? {
        willSet { userListener?.remove() }
    }

    @LazyInjected private var database: Firestore
    @LazyInjected private var healthKitManager: AnyHealthKitManager

    init() {
        if let firebaseUser = Auth.auth().currentUser {
            currentUser = User(id: firebaseUser.uid, email: firebaseUser.email ?? "", name: firebaseUser.displayName ?? "")
            Resolver.register { self.currentUser }
            listenForUser()
        }

        Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            guard let self = self else { return }

            guard let firebaseUser = firebaseUser else {
                self.currentUser = nil
                self.loading = false
                return
            }

            self.healthKitManager.registerForBackgroundDelivery()

            Task { [weak self] in
                guard let self = self else { return }
                let user = try? await self.database.document("users/\(firebaseUser.uid)")
                    .getDocument()
                    .decoded(as: User.self)

                self.listenForUser()

                DispatchQueue.main.async {
                    Resolver.register { user }
                    self.loading = false
                    self.currentUser = user
                }
            }
        }
    }

    private func listenForUser() {
        guard let user = currentUser else { return }
        userListener = database.document("users/\(user.id)")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let user = try? snapshot?.decoded(as: User.self) else { return }
                DispatchQueue.main.async {
                    self.currentUser = user
                }
            }
    }
}
