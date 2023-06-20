import SwiftUI

struct FriendlyCompetitions: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appModel = FriendlyCompetitionsAppModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if appModel.loggedIn {
                    if appModel.emailVerified {
                        RootView()
                    } else {
                        VerifyEmailView()
                    }
                } else {
                    WelcomeView()
                }
            }
            .hud(state: $appModel.hud)
            .onOpenURL(perform: appModel.handle)
        }
    }

}
