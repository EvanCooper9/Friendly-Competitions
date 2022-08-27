import Combine
import CombineExt
import ECKit
import Foundation

enum ActivitySummaryState {
    case found(ActivitySummary)
    case missing
    case permissionsDenied
}

final class DashboardViewModel: ObservableObject {
    
    struct FriendRow: Equatable, Identifiable {
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

    init(activitySummaryManager: ActivitySummaryManaging, competitionsManager: CompetitionsManaging, friendsManager: FriendsManaging, permissionsManager: PermissionsManaging, userManager: UserManaging) {

        activitySummaryManager.activitySummary.assign(to: &$activitySummary)
        competitionsManager.competitions.assign(to: &$competitions)
        competitionsManager.invitedCompetitions.assign(to: &$invitedCompetitions)
        
        let friendRequests = friendsManager.friendRequests
            .map { friendRequests in
                friendRequests.map { friendRequest in
                    FriendRow(
                        user: friendRequest,
                        activitySummary: nil,
                        isInvitation: true
                    )
                }
            }

        let friends = friendsManager.friends
            .combineLatest(friendsManager.friendActivitySummaries)
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

        permissionsManager
            .requiresPermission
            .assign(to: &$requiresPermissions)
        
        userManager.user
            .map { $0.name.ifEmpty(Bundle.main.name) }
            .assign(to: &$title)
    }
}
