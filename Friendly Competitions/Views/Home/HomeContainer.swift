import Resolver
import SwiftUI

struct HomeContainer: View {

    private enum Tab {
        case home
        case explore
    }

    @State private var tab = Tab.home

//    @StateObject private var activitySummaryManager = Resolver.resolve(AnyActivitySummaryManager.self)
//    @StateObject private var competitionsManager = Resolver.resolve(AnyCompetitionsManager.self)
//    @StateObject private var friendsManager = Resolver.resolve(AnyFriendsManager.self)
//    @StateObject private var permissionsManager = Resolver.resolve(AnyPermissionsManager.self)
//    @StateObject private var storageManager = Resolver.resolve(AnyStorageManager.self)
//    @StateObject private var userManager = Resolver.resolve(AnyUserManager.self)

    var body: some View {
        TabView(selection: $tab) {
            Home().tag(Tab.home)
            Explore().tag(Tab.explore)
        }
//        .environmentObject(activitySummaryManager)
//        .environmentObject(competitionsManager)
//        .environmentObject(friendsManager)
//        .environmentObject(permissionsManager)
//        .environmentObject(storageManager)
//        .environmentObject(userManager)
    }
}

struct HomeContainer_Previews: PreviewProvider {

    private static func setupMocks() {
        activitySummaryManager.activitySummary = .mock

        let competitions: [Competition] = [.mock, .mockInvited, .mockOld]
        competitionsManager.appOwnedCompetitions = [.mockPublic, .mockPublic]
        competitionsManager.topCommunityCompetitions = [.mock]
        competitionsManager.competitions = competitions
        competitionsManager.participants = competitions.reduce(into: [:]) { $0[$1.id] = [.evan] }
        competitionsManager.standings = competitions.reduce(into: [:]) { $0[$1.id] = [.mock(for: .evan)] }

        let friend = User.gabby
        friendsManager.friends = [friend]
        friendsManager.friendRequests = [friend]
        friendsManager.friendActivitySummaries = [friend.id: .mock]

        permissionsManager.requiresPermission = false
        permissionsManager.permissionStatus = [
            .health: .authorized,
            .notifications: .authorized
        ]
    }

    static var previews: some View {
        Resolver.register { activitySummaryManager as AnyActivitySummaryManager }
        Resolver.register { competitionsManager as AnyCompetitionsManager }
        Resolver.register { friendsManager as AnyFriendsManager }
        Resolver.register { permissionsManager as AnyPermissionsManager }
        Resolver.register { storageManager as AnyStorageManager }
        Resolver.register { userManager as AnyUserManager }
        return HomeContainer()
            .withEnvironmentObjects(setupMocks: setupMocks)
//            .preferredColorScheme(.dark)
    }
}
