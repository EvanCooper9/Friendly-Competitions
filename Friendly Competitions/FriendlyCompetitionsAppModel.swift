import Combine
import Factory
import Foundation

final class FriendlyCompetitionsAppModel: ObservableObject {

    // MARK: - Public Properties

    @Published private(set)var loggedIn = false
    @Published private(set)var emailVerified = false
    @Published var hud: HUD?

    // MARK: - Private Properties

    @Injected(\.analyticsManager) private var analyticsManager
    @Injected(\.appState) private var appState
    @Injected(\.authenticationManager) private var authenticationManager

    // MARK: - Lifecycle

    init() {
        authenticationManager.loggedIn.assign(to: &$loggedIn)
        authenticationManager.emailVerified.assign(to: &$emailVerified)
        appState.hud.assign(to: &$hud)
    }

    // MARK: - Public Methods

    func handle(url: URL) {
        analyticsManager.log(event: .deepLinked(url: url))
        guard let deepLink = DeepLink(from: url) else { return }
        appState.push(deepLink: deepLink)
    }

    func opened(url: URL) {
        analyticsManager.log(event: .urlOpened(url: url))
    }
}
