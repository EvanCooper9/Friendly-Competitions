import Combine
import Foundation
import Resolver

enum HomeTab {
    case dashboard
    case explore
}

final class HomeViewModel: ObservableObject {
    
    @Published var deepLinkedCompetition: Competition?
    @Published var deepLinkedUser: User?
    
    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var friendsManager: AnyFriendsManager
    
    func handle(url: URL) {
        guard let deepLink = DeepLink(from: url) else { return }
        switch deepLink {
        case .friendReferral(let id):
            Task {
                let user = try await friendsManager.user(withId: id)
                DispatchQueue.main.async { [weak self] in
                    self?.deepLinkedUser = user
                }
            }
        case .competitionInvite(let id):
            Task {
                let competition = try await competitionsManager.search(byID: id)
                DispatchQueue.main.async { [weak self] in
                    self?.deepLinkedCompetition = competition
                }
            }
        }
    }
}
