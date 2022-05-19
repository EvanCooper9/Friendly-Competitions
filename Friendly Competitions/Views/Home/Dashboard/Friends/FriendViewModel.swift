import Combine
import CombineExt
import Resolver

final class FriendViewModel: ObservableObject {
    
    @Published var activitySummary: ActivitySummary?
    @Published var showDeleteConfirmation = false
    @Published var statistics: User.Statistics

    @Injected private var friendsManager: AnyFriendsManager
    
    private let friend: User
    
    init(friend: User) {
        self.friend = friend
        statistics = friend.statistics ?? .zero
    }
    
    func confirm() {
        friendsManager.delete(friend: friend)
    }
    
    func deleteTapped() {
        showDeleteConfirmation.toggle()
    }
}
