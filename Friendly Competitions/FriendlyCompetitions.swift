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
    @StateObject private var appState = AppState()
    @StateObject private var authenticationManager = Resolver.resolve(AnyAuthenticationManager.self)

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authenticationManager.loggedIn {
                    if authenticationManager.emailVerified {
                        Home()
                    } else {
                        VerifyEmail()
                    }
                } else {
                    SignIn()
                }
            }
            .hud(state: $appState.hudState)
            .environmentObject(appState)
            .environmentObject(authenticationManager)
        }
    }
}
