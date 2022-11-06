import Factory
import SwiftUI

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        TabView {
            DashboardView()
                .embeddedInNavigationView()
                .tabItem { Label("Home", systemImage: .houseFill) }
        
            ExploreView()
                .embeddedInNavigationView()
                .tabItem { Label("Explore", systemImage: .sparkleMagnifyingglass) }
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
