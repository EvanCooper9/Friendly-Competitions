import Combine
import CombineExt
import Resolver

final class UserViewModel: ObservableObject {
    
    @Published var title: String
    @Published var activitySummary: ActivitySummary?
    @Published var showDeleteConfirmation = false
    @Published var statistics: User.Statistics
    @Published var actions = [UserViewAction]()
    @Published var confirmationRequired = false
    
    private var actionRequiringConfirmation: UserViewAction? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }

    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var userManager: AnyUserManager
    
    private let user: User
    
    init(user: User) {
        self.user = user
        title = user.name
        statistics = user.statistics ?? .zero
        
        friendsManager.$friendActivitySummaries
            .compactMap { $0[user.id] }
            .assign(to: &$activitySummary)
        
        userManager.$user
            .map { loggedInUser in
                if loggedInUser.friends.contains(user.id) {
                    return [.deleteFriend]
                } else if loggedInUser.incomingFriendRequests.contains(user.id) {
                    return [.acceptFriendRequest, .denyFriendRequest]
                } else {
                    return [.request]
                }
            }
            .assign(to: &$actions)
    }
    
    func confirm() {
        switch actionRequiringConfirmation {
        case .deleteFriend:
            friendsManager.delete(friend: user)
        default:
            break
        }
    }
    
    func perform(_ action: UserViewAction) {
        switch action {
        case .acceptFriendRequest:
            friendsManager.acceptFriendRequest(from: user)
        case .denyFriendRequest:
            friendsManager.declineFriendRequest(from: user)
        case .request:
            friendsManager.add(friend: user)
        case .deleteFriend:
            actionRequiringConfirmation = .deleteFriend
        }
    }
}
