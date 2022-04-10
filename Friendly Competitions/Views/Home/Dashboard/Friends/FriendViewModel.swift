import Combine
import CombineExt
import Resolver

final class FriendViewModel: ObservableObject {
    
    @Published var activitySummary: ActivitySummary?
    @Published var statistics: User.Statistics

    @Injected private var friendsManager: AnyFriendsManager
    
    private let friend: User
    
    private var cancellables = Set<AnyCancellable>()
    
    init(friend: User) {
        self.friend = friend
        statistics = friend.statistics ?? .zero
        
        friendsManager.$friendActivitySummaries
            .map { $0[friend.id] }
            .assign(to: \.activitySummary, on: self, ownership: .weak)
            .store(in: &cancellables)
    }
    
    func delete() {
        friendsManager.delete(friend: friend)
    }
}
