import Combine
import Factory

final class FriendlyCompetitionsAppModel: ObservableObject {
    
    // MARK: - Public Properties

    @Published var loggedIn = false
    @Published var emailVerified = false
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
}
