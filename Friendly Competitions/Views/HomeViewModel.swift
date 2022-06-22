import Combine
import Foundation
import Resolver

final class HomeViewModel: ObservableObject {
    
    @Published var deepLinkedCompetition: Competition?
    @Published var deepLinkedUser: User?
    
    @Injected private var competitionsManager: CompetitionsManaging
    @Injected private var friendsManager: FriendsManaging
    
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
