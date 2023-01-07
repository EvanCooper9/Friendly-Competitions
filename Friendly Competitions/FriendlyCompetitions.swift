import SwiftUI

@main
struct FriendlyCompetitions: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appModel = FriendlyCompetitionsAppModel()
    
    @State private var reload = false

    var body: some Scene {
        WindowGroup {
            if reload {
                ProgressView().onAppear { reload.toggle() }
            } else {
                Group {
                    if appModel.loggedIn {
                        if appModel.emailVerified {
                            RootView()
                        } else {
                            VerifyEmailView()
                        }
                    } else {
                        SignIn()
                    }
                }
                .hud(state: $appModel.hud)
                .onOpenURL(perform: appModel.handle)
                .onReceive(appModel.$environmentUUID.dropFirst()) { _ in reload.toggle() }
            }
        }
    }
}
