import Factory
import SwiftUI

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $viewModel.tab) {
                DashboardView()
                    .embeddedInNavigationView()
                    .tabItem { Label("Home", systemImage: .houseFill) }
                    .tag(HomeTab.dashboard)
            
                ExploreView()
                    .embeddedInNavigationView()
                    .tabItem { Label("Explore", systemImage: .sparkleMagnifyingglass) }
                    .tag(HomeTab.explore)
            }
            
            HStack {
                let ghost = Color.clear
                    .frame(width: 50, height: 1)
                    .padding(.bottom, 50)
                    .maxWidth(.infinity)
                    .allowsHitTesting(false)
                ghost
                    .withTutorialPopup(for: .tabBarDashboard)
                    .onTapGesture { viewModel.tab = .dashboard }
                ghost
                    .withTutorialPopup(for: .tabBarExplore)
                    .onTapGesture { viewModel.tab = .explore }
            }
            .padding(.horizontal, .extraSmall)
            .disabled(!viewModel.tutorialActive)
        }
        .onOpenURL(perform: viewModel.handle)
        .sheet(item: $viewModel.deepLinkedCompetition) { CompetitionView(competition: $0).embeddedInNavigationView() }
        .sheet(item: $viewModel.deepLinkedUser) { UserView(user: $0).embeddedInNavigationView() }
    }
}

struct Home_Previews: PreviewProvider {

    private static func setupMocks() {
        activitySummaryManager.activitySummary = .just(.mock)

        let competitions: [Competition] = [.mock, .mockInvited, .mockOld]
        competitionsManager.appOwnedCompetitions = .just([.mockPublic, .mockPublic])
        competitionsManager.competitions = .just(competitions)
        competitionsManager.participants = .just(competitions.reduce(into: [:]) { $0[$1.id] = [.evan] })
        competitionsManager.standings = .just(competitions.reduce(into: [:]) { $0[$1.id] = [.mock(for: .evan)] })

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
        HomeView()
            .setupMocks(setupMocks)
    }
}
