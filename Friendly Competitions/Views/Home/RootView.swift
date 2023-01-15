import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: .houseFill) }
        
            ExploreView()
                .tabItem { Label("Explore", systemImage: .sparkleMagnifyingglass) }
        }
    }
}

#if DEBUG
struct Home_Previews: PreviewProvider {

    private static func setupMocks() {
        activitySummaryManager.activitySummary = .just(.mock)

        let competitions: [Competition] = [.mock, .mockInvited, .mockOld]
        competitionsManager.appOwnedCompetitions = .just([.mockPublic, .mockPublic])
        competitionsManager.competitions = .just(competitions)
        competitionsManager.participantsForReturnValue = .just([.evan])
        competitionsManager.standingsForReturnValue = .just([.mock(for: .evan)])

        let friend = User.gabby
        friendsManager.friends = .just([friend])
        friendsManager.friendRequests = .just([friend])
        friendsManager.friendActivitySummaries = .just([friend.id: .mock])

        permissionsManager.requiresPermission = .just(false)
        permissionsManager.permissionStatus = .just([
            .health: .authorized,
            .notifications: .authorized
        ])
    }

    static var previews: some View {
        RootView()
            .setupMocks(setupMocks)
    }
}
#endif
