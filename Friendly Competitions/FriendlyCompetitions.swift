import Firebase
import Resolver
import SwiftUI

#if DEBUG
let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#endif

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

    @Published var loggedIn = false
    @Published var emailVerified = false
    @Published var hud: HUDState?

    @Injected private var appState: AppState
    @Injected private var authenticationManager: AuthenticationManaging

    init() {
        authenticationManager.loggedIn.assign(to: &$loggedIn)
        authenticationManager.emailVerified.assign(to: &$emailVerified)
        appState.$hudState.assign(to: &$hud)
    }
}
