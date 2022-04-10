import Combine
import CombineExt
import Resolver
import Foundation

//@MainActor
final class DashboardViewModel: ObservableObject {
    
    @Published private(set) var activitySummary: ActivitySummary?
    @Published private(set) var friendActivitySummaries = [User.ID: ActivitySummary]()
    
    @Published private(set) var competitions = [Competition]()
    @Published private(set) var invitedCompetitions = [Competition]()
    @Published private(set) var friends = [User]()
    @Published private(set) var friendRequests = [User]()
    @Published var user: User!
    
    @Published var requiresPermissions = false
    
    @Injected private var activitySummaryManager: AnyActivitySummaryManager
    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var permissionsManager: AnyPermissionsManager
    @Injected private var userManager: AnyUserManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        user = userManager.user
        
        activitySummaryManager.$activitySummary
            .assign(to: \.activitySummary, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        competitionsManager.$competitions
            .assign(to: \.competitions, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        friendsManager.$friends
            .assign(to: \.friends, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        friendsManager.$friendActivitySummaries
            .assign(to: \.friendActivitySummaries, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        friendsManager.$friendRequests
            .assign(to: \.friendRequests, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        permissionsManager.$requiresPermission
            .assign(to: \.requiresPermissions, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        userManager.$user
            .assign(to: \.user, on: self, ownership: .weak)
            .store(in: &cancellables)
    }
    
    func acceptFriendRequest(from user: User) {
        friendsManager.acceptFriendRequest(from: user)
    }
    
    func declineFriendRequest(from user: User) {
        friendsManager.declineFriendRequest(from: user)
    }
}
