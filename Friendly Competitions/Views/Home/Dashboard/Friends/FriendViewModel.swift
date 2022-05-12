import Combine
import CombineExt
import Resolver

final class FriendViewModel: ObservableObject {
    
    @Published var activitySummary: ActivitySummary?
    @Published var statistics: User.Statistics

    @Injected private var friendsManager: AnyFriendsManager
    
    private let friend: User
    
    init(friend: User) {
        self.friend = friend
        statistics = friend.statistics ?? .zero
        
        friendsManager.$friendActivitySummaries
            .map { $0[friend.id] }
            .assign(to: &$activitySummary)
    }
    
    func delete() {
        friendsManager.delete(friend: friend)
    }
}
