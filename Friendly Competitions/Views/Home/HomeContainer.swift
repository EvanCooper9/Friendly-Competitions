import Resolver
import SwiftUI

struct HomeContainer: View {

    @StateObject private var activitySummaryManager = Resolver.resolve(AnyActivitySummaryManager.self)
    @StateObject private var competitionsManager = Resolver.resolve(AnyCompetitionsManager.self)
    @StateObject private var friendsManager = Resolver.resolve(AnyFriendsManager.self)
    @StateObject private var permissionsManager = Resolver.resolve(AnyPermissionsManager.self)
    @StateObject private var storageManager = Resolver.resolve(AnyStorageManager.self)
    @StateObject private var userManager = Resolver.resolve(AnyUserManager.self)

    var body: some View {
        TabView {
            Home()
            Explore()
        }
        .environmentObject(activitySummaryManager)
        .environmentObject(competitionsManager)
        .environmentObject(friendsManager)
        .environmentObject(permissionsManager)
        .environmentObject(storageManager)
        .environmentObject(userManager)
    }
}

struct HomeContainer_Previews: PreviewProvider {
    
    private static let activitySummaryManager: AnyActivitySummaryManager = {
        let activitySummaryManager = AnyActivitySummaryManager()
        activitySummaryManager.activitySummary = .mock
        return activitySummaryManager
    }()

    private static let competitionsManager: AnyCompetitionsManager = {
        let competitions: [Competition] = [.mock, .mockInvited, .mockOld]
        let competitionManager = AnyCompetitionsManager()
        competitionManager.competitions = competitions
        competitionManager.standings = competitions.reduce(into: [:]) { partialResult, competition in
            partialResult[competition.id] = [.mock(for: .evan)]
        }
        return competitionManager
    }()

    private static let friendsManager: AnyFriendsManager = {
        let friend = User.gabby
        friend.tempActivitySummary = .mock
        let friendsManager = AnyFriendsManager()
        friendsManager.friends = [friend]
        friendsManager.friendRequests = [friend]
        return friendsManager
    }()

    private static let permissionsManager: AnyPermissionsManager = {
        let permissionsManager = AnyPermissionsManager()
        permissionsManager.requiresPermission = false
        permissionsManager.permissionStatus = [
            .health: .authorized,
            .notifications: .authorized
        ]
        return permissionsManager
    }()

    private static let storageManager: AnyStorageManager = {
        return AnyStorageManager()
    }()

    private static let userManager: AnyUserManager = {
        return AnyUserManager(user: .evan)
    }()

    static var previews: some View {
        Resolver.register { activitySummaryManager as AnyActivitySummaryManager }
        Resolver.register { competitionsManager as AnyCompetitionsManager }
        Resolver.register { friendsManager as AnyFriendsManager }
        Resolver.register { permissionsManager as AnyPermissionsManager }
        Resolver.register { storageManager as AnyStorageManager }
        Resolver.register { userManager as AnyUserManager }
        return HomeContainer()
            .environmentObject(activitySummaryManager)
            .environmentObject(competitionsManager)
            .environmentObject(friendsManager)
            .environmentObject(permissionsManager)
            .environmentObject(storageManager)
            .environmentObject(userManager)
    }
}
