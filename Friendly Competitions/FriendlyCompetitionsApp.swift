import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Resolver

@main
struct FriendlyCompetitionsApp: App {

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
                if !appModel.hasCompletedHealthPermissions {
                    HealthKitPermissionsView(done: { appModel.healthPermissionsComplete() })
                } else if !appModel.hasCompletedContactsPermissions {
                    ContactsPermissionsView(done: { appModel.contactsPermissionsComplete() })
                } else {
                    HomeView().environmentObject(user)
                }
            } else {
                SignInView()
            }
        }
    }
}

@MainActor
final class AppModel: ObservableObject {

    @Published var loading = true
    @Published var currentUser: User?
    @Published var hasCompletedHealthPermissions = false
    @Published var hasCompletedContactsPermissions = false

    private var userHandle: AuthStateDidChangeListenerHandle?

    @LazyInjected private var activitySummaryManager: ActivitySummaryManaging
    @LazyInjected private var contactsManager: ContactsManaging
    @LazyInjected private var database: Firestore
    @LazyInjected private var healthKitManager: HealthKitManaging

    init() {
        activitySummaryManager.registerForBackgroundDelivery()
        healthKitManager.registerForBackgroundDelivery()

        hasCompletedHealthPermissions = !healthKitManager.shouldRequestPermissions
        hasCompletedContactsPermissions = !contactsManager.shouldRequestPermissions

        userHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            guard let self = self else { return }

            guard let firebaseUser = firebaseUser else {
                self.currentUser = nil
                self.loading = false
                return
            }

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

    func healthPermissionsComplete() {
        hasCompletedHealthPermissions = !healthKitManager.shouldRequestPermissions
    }

    func contactsPermissionsComplete() {
        hasCompletedContactsPermissions = !contactsManager.shouldRequestPermissions
    }
}
