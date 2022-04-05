import Resolver
import SwiftUI

struct Home: View {

    private enum Tab {
        case dashboard
        case explore
    }

    @State private var tab = Tab.dashboard

    var body: some View {
        TabView(selection: $tab) {
            Dashboard().tag(Tab.dashboard)
            Explore().tag(Tab.explore)
        }
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
        registerDependencies()
        return Home()
            .setupMocks(setupMocks)
    }
}
