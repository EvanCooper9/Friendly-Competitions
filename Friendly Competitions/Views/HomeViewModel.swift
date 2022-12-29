import Combine
import Factory
import Foundation

final class HomeViewModel: ObservableObject {
    
    // MARK: - Public Properties
    
    @Published var tab = HomeTab.dashboard
    @Published var deepLinkedCompetition: Competition?
    @Published var deepLinkedUser: User?
    
    @Published private(set) var tutorialActive = false
    
    // MARK: - Private Properties
    
    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.friendsManager) private var friendsManager
    @Injected(Container.tutorialManager) private var tutorialManager
    
    // MARK: - Lifecycle
    
    init() {
        tutorialManager.remainingSteps
            .map(\.isNotEmpty)
            .assign(to: &$tutorialActive)
    }
    
    // MARK: - Public Methods
    
    func handle(url: URL) {
        guard let deepLink = DeepLink(from: url) else { return }
        switch deepLink {
        case .friendReferral(let id):
            friendsManager.user(withId: id)
                .ignoreFailure()
                .receive(on: RunLoop.main)
                .assign(to: &$deepLinkedUser)
        case .competitionInvite(let id):
            competitionsManager.search(byID: id)
                .ignoreFailure()
                .receive(on: RunLoop.main)
                .assign(to: &$deepLinkedCompetition)
        }
    }
}
