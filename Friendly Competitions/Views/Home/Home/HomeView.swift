import SwiftUI
import SwiftUIX

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
            
    @State private var presentAbout = false
    @State private var presentDeveloper = false
    @State private var presentPermissions = false
    @State private var presentNewCompetition = false
    @State private var presentSearchFriendsSheet = false
    @AppStorage("competitionsFiltered") var competitionsFiltered = false
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationDestinations) {
            List {
                if viewModel.showPremiumBanner {
                    premiumBanner
                }
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
                    if viewModel.showDeveloper {
                        Button(systemImage: .hammer) { presentDeveloper.toggle() }
                    }
                    Button(systemImage: .questionmarkCircle) { presentAbout.toggle() }
                    
                    NavigationLink(value: NavigationDestination.profile) {
                        Image(systemName: .personCropCircle)
                    }
                }
            }
            .sheet(isPresented: $presentAbout, content: About.init)
            .sheet(isPresented: $presentSearchFriendsSheet) { InviteFriendsView(action: .addFriend) }
            .sheet(isPresented: $presentNewCompetition, content: NewCompetitionView.init)
            .sheet(isPresented: $viewModel.requiresPermissions, content: PermissionsView.init)
            .sheet(isPresented: $presentDeveloper, content: DeveloperView.init)
            .sheet(isPresented: $viewModel.showPaywall, content: PaywallView.init)
            .withLoadingOverlay(isLoading: viewModel.loadingDeepLink)
            .navigationDestination(for: NavigationDestination.self) { $0.view }
            .registerScreenView(name: "Home")
        }
    }
    
    private var premiumBanner: some View {
        Section {
            PremiumBanner().overlay {
                Button(systemImage: .xmark, action: viewModel.dismissPremiumBannerTapped)
                    .padding(14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .buttonStyle(.plain)
            }
        }
        .listRowInsets(.zero)
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
            ForEach(viewModel.competitions + viewModel.invitedCompetitions) { competition in
                if competitionsFiltered ? competition.isActive : true {
                    NavigationLink(value: NavigationDestination.competition(competition)) {
                        CompetitionDetails(competition: competition, showParticipantCount: false, isFeatured: false)
                    }
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
                    Image(systemName: .plusCircle)
                        .font(.title2)
                }
            }
        } footer: {
            if viewModel.competitions.isEmpty && viewModel.invitedCompetitions.isEmpty {
                Text("Start a competition against your friends!")
            }
        }
    }
    
    private var friends: some View {
        Section {
            ForEach(viewModel.friendRows) { row in
                NavigationLink(value: NavigationDestination.user(row.user)) {
                    HStack {
                        ActivityRingView(activitySummary: row.activitySummary?.hkActivitySummary)
                            .frame(width: 35, height: 35)
                        Text(row.user.name)
                        Spacer()
                        if row.isInvitation {
                            Text("Invited")
                                .foregroundColor(.secondaryLabel)
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
                    Image(systemName: .personCropCircleBadgePlus)
                        .font(.title2)
                }
            }
        } footer: {
            if viewModel.friendRows.isEmpty {
                Text("Add friends to get started!")
            }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    
    private static func setupMocks() {
        activitySummaryManager.activitySummary = .just(.mock)
        
        competitionsManager.competitions = .just([.mock, .mockInvited, .mockOld, .mockPublic])
        competitionsManager.participantsForReturnValue = .just([.evan])
        competitionsManager.standingsPublisherForReturnValue = .just([.mock(for: .evan)])

        friendsManager.friends = .just([.gabby])
        friendsManager.friendRequests = .just([.andrew])
        friendsManager.friendActivitySummaries = .just([User.gabby.id: .mock])
        
        permissionsManager.requiresPermission = .just(false)
        permissionsManager.permissionStatus = .just([
            .health: .authorized,
            .notifications: .authorized
        ])
    }
    
    static var previews: some View {
        HomeView()
            .setupMocks(setupMocks)
            .embeddedInNavigationView()
    }
}
#endif
