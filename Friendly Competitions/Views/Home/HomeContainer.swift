import Resolver
import SwiftUI

enum Tab {
    case home
    case explore
}

struct HomeContainer: View {

    @State private var tab = Tab.home

    @StateObject private var activitySummaryManager = Resolver.resolve(AnyActivitySummaryManager.self)
    @StateObject private var competitionsManager = Resolver.resolve(AnyCompetitionsManager.self)
    @StateObject private var friendsManager = Resolver.resolve(AnyFriendsManager.self)
    @StateObject private var permissionsManager = Resolver.resolve(AnyPermissionsManager.self)
    @StateObject private var userManager = Resolver.resolve(AnyUserManager.self)

    var body: some View {
        TabView {
            Home()
                .tag(Tab.home)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            ExploreCompetitions()
                .tag(Tab.explore)
                .tabItem {
                    Label("Explore", systemImage: "sparkle.magnifyingglass")
                }
        }
        .environmentObject(activitySummaryManager)
        .environmentObject(competitionsManager)
        .environmentObject(friendsManager)
        .environmentObject(permissionsManager)
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

    private static let userManager: AnyUserManager = {
        return AnyUserManager(user: .evan)
    }()

    static var previews: some View {
        Resolver.register { activitySummaryManager as AnyActivitySummaryManager }
        Resolver.register { competitionsManager as AnyCompetitionsManager }
        Resolver.register { friendsManager as AnyFriendsManager }
        Resolver.register { permissionsManager as AnyPermissionsManager }
        Resolver.register { userManager as AnyUserManager }
        return HomeContainer()
            .environmentObject(activitySummaryManager)
            .environmentObject(competitionsManager)
            .environmentObject(friendsManager)
            .environmentObject(permissionsManager)
            .environmentObject(userManager)
    }
}
