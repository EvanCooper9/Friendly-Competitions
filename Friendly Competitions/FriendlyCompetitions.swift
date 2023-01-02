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
                        RootView()
                            .onOpenURL(perform: appModel.handle)
                    } else {
                        VerifyEmailView()
                            .onOpenURL(perform: appModel.handle)
                    }
                } else {
                    SignIn()
                        .onOpenURL(perform: appModel.handle)
                }
            }
            .hud(state: $appModel.hud)
        }
    }
}
