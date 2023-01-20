import Combine
import Factory
import Foundation

final class FriendlyCompetitionsAppModel: ObservableObject {
    
    // MARK: - Public Properties

    @Published private(set)var loggedIn = false
    @Published private(set)var emailVerified = false
    @Published var hud: HUD?
    
    // MARK: - Private Properties

    @Injected(Container.appState) private var appState
    @Injected(Container.authenticationManager) private var authenticationManager
    
    // MARK: - Lifecycle

    init() {
        authenticationManager.loggedIn.assign(to: &$loggedIn)
        authenticationManager.emailVerified.assign(to: &$emailVerified)
        appState.hud.assign(to: &$hud)
    }
    
    // MARK: - Public Methods
    
    func handle(url: URL) {
        guard let deepLink = DeepLink(from: url) else { return }
        appState.push(deepLink: deepLink)
    }
}
