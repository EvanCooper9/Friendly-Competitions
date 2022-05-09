import Combine
import CombineExt
import Resolver
import Foundation

final class DashboardViewModel: ObservableObject {
    
    @Published private(set) var activitySummary: ActivitySummary?
    @Published private(set) var friendActivitySummaries = [User.ID: ActivitySummary]()
    @Published private(set) var competitions = [Competition]()
    @Published private(set) var invitedCompetitions = [Competition]()
    @Published private(set) var friends = [User]()
    @Published private(set) var friendRequests = [User]()
    @Published private(set) var user: User!
    
    @Published var requiresPermissions = false
    
    @Injected private var activitySummaryManager: AnyActivitySummaryManager
    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var permissionsManager: AnyPermissionsManager
    @Injected private var userManager: AnyUserManager
        
    init() {
        user = userManager.user
        activitySummaryManager.$activitySummary.assign(to: &$activitySummary)
        competitionsManager.$competitions.assign(to: &$competitions)
        competitionsManager.$invitedCompetitions.assign(to: &$invitedCompetitions)
        friendsManager.$friends.assign(to: &$friends)
        friendsManager.$friendActivitySummaries.assign(to: &$friendActivitySummaries)
        friendsManager.$friendRequests.assign(to: &$friendRequests)
        permissionsManager.$requiresPermission.assign(to: &$requiresPermissions)
        userManager.$user.map { $0 as User? }.assign(to: &$user)
    }
    
    func acceptFriendRequest(from user: User) {
        friendsManager.acceptFriendRequest(from: user)
    }
    
    func declineFriendRequest(from user: User) {
        friendsManager.declineFriendRequest(from: user)
    }
}
