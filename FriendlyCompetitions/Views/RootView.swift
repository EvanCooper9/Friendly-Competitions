import SwiftUI

struct RootView: View {

    @StateObject private var viewModel = RootViewModel()

    var body: some View {
        TabView(selection: $viewModel.tab) {
            HomeView()
                .tabItem { Label(L10n.Root.home, systemImage: .houseFill) }
                .tag(RootTab.home)

            ExploreView()
                .tabItem { Label(L10n.Root.explore, systemImage: .sparkleMagnifyingglass) }
                .tag(RootTab.explore)

            SettingsView()
                .tabItem { Label(L10n.Root.settings, systemImage: .gear) }
                .tag(RootTab.settings)
        }
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {

    private static func setupMocks() {
        activitySummaryManager.activitySummary = .just(.mock)

        competitionsManager.appOwnedCompetitions = .just([.mockPublic, .mockPublic])
        competitionsManager.competitions = .just([.mock, .mockInvited, .mockOld])
        competitionsManager.standingsPublisherForLimitReturnValue = .just([.mock(for: .evan)])

        let friend = User.gabby
        friendsManager.friends = .just([friend])
        friendsManager.friendRequests = .just([friend])
        friendsManager.friendActivitySummaries = .just([friend.id: .mock])

        searchManager.searchForUsersWithIDsReturnValue = .just([.evan])
    }

    static var previews: some View {
        RootView()
            .setupMocks(setupMocks)
    }
}
#endif
