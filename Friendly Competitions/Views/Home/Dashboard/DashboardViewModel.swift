import Combine
import CombineExt
import Resolver
import Foundation

final class DashboardViewModel: ObservableObject {
    
    struct FriendRow: Identifiable {
        var id: String { user.id }
        let user: User
        let activitySummary: ActivitySummary?
        let isInvitation: Bool
    }
    
    @Published private(set) var activitySummary: ActivitySummary?
    @Published private(set) var competitions = [Competition]()
    @Published private(set) var friends = [FriendRow]()
    @Published private(set) var invitedCompetitions = [Competition]()
    @Published var requiresPermissions = false
    @Published private(set) var title = Bundle.main.name
    
    @Injected private var activitySummaryManager: AnyActivitySummaryManager
    @Injected private var competitionsManager: CompetitionsManaging
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var permissionsManager: AnyPermissionsManager
    @Injected private var userManager: AnyUserManager
    
    private var cancellables = Set<AnyCancellable>()
        
    init() {
        activitySummaryManager.$activitySummary.assign(to: &$activitySummary)
        competitionsManager.competitions.assign(to: &$competitions)
        competitionsManager.invitedCompetitions.assign(to: &$invitedCompetitions)
        
        let friendRequests = friendsManager.$friendRequests
            .map { friendRequests in
                friendRequests.map { friendRequest in
                    FriendRow(
                        user: friendRequest,
                        activitySummary: nil,
                        isInvitation: true
                    )
                }
            }
        
        let friends = friendsManager.$friends
            .combineLatest(friendsManager.$friendActivitySummaries)
            .map { friends, activitySummaries in
                friends.map { friend in
                    FriendRow(
                        user: friend,
                        activitySummary: activitySummaries[friend.id],
                        isInvitation: false
                    )
                }
            }
        
        Publishers.CombineLatest(friends, friendRequests)
            .map { $0 + $1 }
            .assign(to: &$friends)
        
        permissionsManager.$requiresPermission.assign(to: &$requiresPermissions)
        
        userManager.$user
            .map { $0.name.ifEmpty(Bundle.main.name) }
            .assign(to: &$title)
    }
    
    func acceptFriendRequest(from user: User) {
        friendsManager.acceptFriendRequest(from: user)
    }
    
    func declineFriendRequest(from user: User) {
        friendsManager.declineFriendRequest(from: user)
    }
}
