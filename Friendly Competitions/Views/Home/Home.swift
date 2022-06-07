import Resolver
import SwiftUI

struct Home: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        TabView {
            Dashboard()
                .embeddedInNavigationView()
                .tabItem { Label("Home", systemImage: .houseFill) }
        
            Explore()
                .embeddedInNavigationView()
                .tabItem { Label("Explore", systemImage: .sparkleMagnifyingglass) }
        }
        .onOpenURL(perform: viewModel.handle(url:))
        .sheet(item: $viewModel.deepLinkedCompetition) { CompetitionView(competition: $0).embeddedInNavigationView() }
        .sheet(item: $viewModel.deepLinkedUser) { UserView(user: $0).embeddedInNavigationView() }
    }
}

struct HomeContainer_Previews: PreviewProvider {

    private static func setupMocks() {
        activitySummaryManager.activitySummary = .mock

        let competitions: [Competition] = [.mock, .mockInvited, .mockOld]
        competitionsManager.appOwnedCompetitions = .just([.mockPublic, .mockPublic])
        competitionsManager.topCommunityCompetitions = .just([.mock])
        competitionsManager.competitions = .just(competitions)
        competitionsManager.participants = .just(competitions.reduce(into: [:]) { $0[$1.id] = [.evan] })
        competitionsManager.standings = .just(competitions.reduce(into: [:]) { $0[$1.id] = [.mock(for: .evan)] })

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
        Home()
            .setupMocks(setupMocks)
    }
}
