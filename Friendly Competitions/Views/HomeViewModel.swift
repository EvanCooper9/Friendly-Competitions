import Combine
import Factory
import Foundation

final class HomeViewModel: ObservableObject {
    
    // MARK: - Public Properties
    
    @Published var deepLinkedCompetition: Competition?
    @Published var deepLinkedUser: User?
    
    // MARK: - Private Properties
    
    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.friendsManager) private var friendsManager
    
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
