import Factory
import Firebase
import SwiftUI

@main
struct FriendlyCompetitions: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// Can't use `@InjectedObject` or else Firebase crashes because `FirebaseApp.configure` isn't called first.
    @StateObject private var appModel = FriendlyCompetitionsAppModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appModel.loggedIn {
                    if appModel.emailVerified {
                        Home()
                    } else {
                        VerifyEmail()
                    }
                } else {
                    SignIn()
                }
            }
            .hud(state: $appModel.hud)
        }
    }
}

final class FriendlyCompetitionsAppModel: ObservableObject {
    
    // MARK: - Public Properties

    @Published var loggedIn = false
    @Published var emailVerified = false
    @Published var hud: HUDState?
    
    // MARK: - Private Properties

    @Injected(Container.appState) private var appState
    @Injected(Container.authenticationManager) private var authenticationManager
    
    // MARK: - Lifecycle

    init() {
        authenticationManager.loggedIn.assign(to: &$loggedIn)
        authenticationManager.emailVerified.assign(to: &$emailVerified)
        appState.$hudState.assign(to: &$hud)
    }
}
