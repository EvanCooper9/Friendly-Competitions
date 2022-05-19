import Combine
import CombineExt
import Resolver
import Foundation

final class DashboardViewModel: ObservableObject {
    
    struct FriendRow: Identifiable {
        let id: User.ID
        let name: String
        let activitySummary: ActivitySummary?
    }
    
    @Published private(set) var activitySummary: ActivitySummary?
    @Published private(set) var competitions = [Competition]()
    @Published private(set) var friends = [FriendRow]()
    @Published private(set) var friendRequests = [FriendRow]()
    @Published private(set) var invitedCompetitions = [Competition]()
    @Published var requiresPermissions = false
    @Published private(set) var title = Bundle.main.name
    
    @Injected private var activitySummaryManager: AnyActivitySummaryManager
    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var permissionsManager: AnyPermissionsManager
    @Injected private var userManager: AnyUserManager
        
    init() {
        activitySummaryManager.$activitySummary.assign(to: &$activitySummary)
        competitionsManager.$competitions.assign(to: &$competitions)
        competitionsManager.$invitedCompetitions.assign(to: &$invitedCompetitions)
        
        friendsManager.$friendRequests
            .map { friendRequests in
                friendRequests.map { friendRequest in
                    FriendRow(
                        id: friendRequest.id,
                        name: friendRequest.name,
                        activitySummary: nil
                    )
                }
            }
            .assign(to: &$friendRequests)
        
        friendsManager.$friends
            .combineLatest(friendsManager.$friendActivitySummaries)
            .map { friends, activitySummaries in
                friends.map { friend in
                    FriendRow(
                        id: friend.id,
                        name: friend.name,
                        activitySummary: activitySummaries[friend.id]
                    )
                }
            }
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
