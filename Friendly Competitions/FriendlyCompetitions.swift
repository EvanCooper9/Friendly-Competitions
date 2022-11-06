import SwiftUI

@main
struct FriendlyCompetitions: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appModel = FriendlyCompetitionsAppModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if appModel.loggedIn {
                    if appModel.emailVerified {
                        HomeView()
                    } else {
                        VerifyEmailView()
                    }
                } else {
                    SignIn()
                }
            }
            .hud(state: $appModel.hud)
        }
    }
}
