import Resolver
import SwiftUI

struct Dashboard: View {
    
    @StateObject private var viewModel = DashboardViewModel()
    
    @EnvironmentObject private var appState: AppState
        
    @State private var presentAbout = false
    @State private var presentPermissions = false
    @State private var presentNewCompetition = false
    @State private var presentSearchFriendsSheet = false
    @AppStorage("competitionsFiltered") var competitionsFiltered = false
    
    var body: some View {
        List {
            Group {
                activitySummary
                competitions
                friends
            }
            .textCase(nil)
        }
        .navigationBarTitle(viewModel.title)
        .toolbar {
            HStack {
                Button(toggling: $presentAbout) {
                    Image(systemName: .questionmarkCircle)
                }
                NavigationLink {
                    Profile()
                } label: {
                    Image(systemName: .personCropCircle)
                }
            }
        }
        .sheet(isPresented: $presentAbout) { About() }
        .sheet(isPresented: $presentSearchFriendsSheet) { InviteFriends(action: .addFriend) }
        .sheet(isPresented: $presentNewCompetition) { NewCompetition() }
        .sheet(isPresented: $viewModel.requiresPermissions) { PermissionsView() }
        .registerScreenView(name: "Home")
    }
    
    private var activitySummary: some View {
        Section {
            ActivitySummaryInfoView(activitySummary: viewModel.activitySummary)
        } header: {
            Text("Activity").font(.title3)
        } footer: {
            if viewModel.activitySummary == nil {
                Text("Have you worn your watch today? We can't find any activity summaries yet. If this is a mistake, please make sure that permissions are enabled in the Health app.")
            }
        }
    }
    
    private var competitions: some View {
        Section {
            ForEach(viewModel.competitions) { competition in
                if competitionsFiltered ? competition.isActive : true {
                    CompetitionDetails(competition: competition, showParticipantCount: false, isFeatured: false)
                }
            }
            ForEach(viewModel.invitedCompetitions) { competition in
                if competitionsFiltered ? competition.isActive : true {
                    CompetitionDetails(competition: competition, showParticipantCount: false, isFeatured: false)
                }
            }
        } header: {
            HStack {
                let text = competitionsFiltered ? "Active competitions" : "Competitions"
                Text(text).font(.title3)
                Spacer()
                Button {
                    withAnimation { competitionsFiltered.toggle() }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle\(competitionsFiltered ? ".fill" : "")")
                        .font(.title2)
                }
                .disabled(viewModel.competitions.isEmpty)
                
                Button(toggling: $presentNewCompetition) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                }
            }
        } footer: {
            if viewModel.competitions.isEmpty {
                Text("Start a competition against your friends!")
            }
        }
    }
    
    private var friends: some View {
        Section {
            ForEach(viewModel.friends) { row in
                NavigationLink {
                    UserView(user: row.user)
                } label: {
                    HStack {
                        ActivityRingView(activitySummary: row.activitySummary?.hkActivitySummary)
                            .frame(width: 35, height: 35)
                        Text(row.user.name)
                        Spacer()
                        if row.isInvitation {
                            Text("Invited")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Friends")
                    .font(.title3)
                Spacer()
                Button(toggling: $presentSearchFriendsSheet) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                }
            }
        } footer: {
            if viewModel.friends.isEmpty {
                Text("Add friends to get started!")
            }
        }
    }
}

struct Dashboard_Previews: PreviewProvider {
    
    private static func setupMocks() {
        activitySummaryManager.activitySummary = .mock
        
        let competitions: [Competition] = [.mock, .mockInvited, .mockOld, .mockPublic]
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
        Dashboard()
            .setupMocks(setupMocks)
            .embeddedInNavigationView()
    }
}
