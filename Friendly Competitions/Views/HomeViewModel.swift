import Combine
import Foundation

final class HomeViewModel: ObservableObject {
    
    @Published var deepLinkedCompetition: Competition?
    @Published var deepLinkedUser: User?
    
    private let competitionsManager: CompetitionsManaging
    private let friendsManager: FriendsManaging

    init(competitionsManager: CompetitionsManaging, friendsManager: FriendsManaging) {
        self.competitionsManager = competitionsManager
        self.friendsManager = friendsManager
    }
    
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
