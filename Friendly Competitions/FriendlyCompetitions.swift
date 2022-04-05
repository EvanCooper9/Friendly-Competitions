import Firebase
import Resolver
import SwiftUI

var isPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }

@main
struct FriendlyCompetitions: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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
            .environmentObject(authenticationManager)
        }
    }
}
