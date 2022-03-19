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

    private static func setupMocks() {
        activitySummaryManager.activitySummary = .mock

        let competitions: [Competition] = [.mock, .mockInvited, .mockOld]
        competitionsManager.competitions = competitions
        competitionsManager.participants = competitions.reduce(into: [:]) { partialResult, competition in
            partialResult[competition.id] = [.evan]
        }
        competitionsManager.standings = competitions.reduce(into: [:]) { partialResult, competition in
            partialResult[competition.id] = [.mock(for: .evan)]
        }

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
    }
}
