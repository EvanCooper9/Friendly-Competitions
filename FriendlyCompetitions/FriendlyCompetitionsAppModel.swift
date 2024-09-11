import Combine
import Factory
import FCKit
import Foundation

final class FriendlyCompetitionsAppModel: ObservableObject {

    // MARK: - Public Properties

    @Published private(set) var needsUpgrade = false
    @Published private(set) var loggedIn = false
    @Published private(set) var emailVerified = false
    @Published var hud: HUD?

    // MARK: - Private Properties

    @Injected(\.analyticsManager) private var analyticsManager: AnalyticsManaging
    @Injected(\.appState) private var appState: AppStateProviding
    @Injected(\.authenticationManager) private var authenticationManager: AuthenticationManaging
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging

    // MARK: - Lifecycle

    init() {
        authenticationManager.loggedIn.assign(to: &$loggedIn)
        authenticationManager.emailVerified.assign(to: &$emailVerified)
        appState.hud.assign(to: &$hud)
        checkMinimumVersion()
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

    // MARK: - Private Methods

    private func checkMinimumVersion() {
        #if RELEASE
        let currentVersion = Bundle.main.version
        let minimumVersion = featureFlagManager.value(forString: .minimumAppVersion)
        needsUpgrade = currentVersion.compare(minimumVersion, options: .numeric) == .orderedAscending
        #endif
    }
}
