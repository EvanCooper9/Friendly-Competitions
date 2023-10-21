import ECKit
import SwiftUI
import SwiftUIX

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack(path: $viewModel.navigationDestinations) {
            CustomList {

                ItemStack(models: viewModel.banners) { banner in
                    banner.view {
                        viewModel.tapped(banner: banner)
                    }
                }
                .padding(.horizontal)

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
                ToolbarItemGroup {
                    // Text view workaround for SwiftUI bug
                    // Keep toolbar items tappable after dismissing sheet
                    let isShowingSheet = viewModel.showAbout || viewModel.navigationDestinations.contains(.profile)
                    Text(isShowingSheet  ? " " : "")

                    if viewModel.showDeveloper {
                        DeveloperMenu()
                    }
                    Button(systemImage: .questionmarkCircle, action: viewModel.aboutTapped)

                    NavigationLink(value: NavigationDestination.profile) {
                        Image(systemName: .personCropCircle)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAbout, content: AboutView.init)
            .sheet(isPresented: $viewModel.showAnonymousAccountBlocker, content: CreateAccountView.init)
            .sheet(item: $viewModel.deepLinkedNavigationDestination) { destination in
                destination.view
                    .embeddedInNavigationView()
            }
            .withLoadingOverlay(isLoading: viewModel.loadingDeepLink)
            .navigationDestination(for: NavigationDestination.self) { $0.view }
            .animation(.default, value: viewModel.banners)
            .registerScreenView(name: "Home")
        }
    }

    private var premiumBanner: some View {
        CustomListSection {
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
        CustomListSection {
            ActivitySummaryInfoView(source: .local)
        } header: {
            Text(L10n.Home.Section.Activity.title)
        }
    }

    private var competitions: some View {
        CustomListSection {
            ForEach(viewModel.competitions + viewModel.invitedCompetitions) { competition in
                NavigationLink(value: NavigationDestination.competition(competition)) {
                    CompetitionDetails(competition: competition, showParticipantCount: false, isFeatured: false)
                }
                .buttonStyle(.plain)
            }
        } header: {
            HStack {
                Text(L10n.Home.Section.Competitions.title)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: viewModel.newCompetitionTapped) {
                    Image(systemName: .plusCircle)
                        .font(.title3)
                }
            }
        } footer: {
            if viewModel.competitions.isEmpty && viewModel.invitedCompetitions.isEmpty {
                Text(L10n.Home.Section.Competitions.createPrompt)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $viewModel.showNewCompetition) {
            CompetitionEditView(competition: nil)
        }
    }

    private var friends: some View {
        CustomListSection {
            ForEach(viewModel.friendRows) { row in
                NavigationLink(value: NavigationDestination.user(row.user)) {
                    HStack {
                        ActivityRingView(activitySummary: row.activitySummary?.hkActivitySummary)
                            .frame(width: 35, height: 35)
                        Text(row.user.name)
                        Spacer()
                        if row.isInvitation {
                            Text(L10n.Home.Section.Friends.invited)
                                .foregroundColor(.secondaryLabel)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            HStack {
                Text(L10n.Home.Section.Friends.title)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: viewModel.addFriendsTapped) {
                    Image(systemName: .personCropCircleBadgePlus)
                        .font(.title3)
                }
            }
        } footer: {
            if viewModel.friendRows.isEmpty {
                Text(L10n.Home.Section.Friends.addPrompt)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $viewModel.showAddFriends) { InviteFriendsView(action: .addFriend) }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {

    private static func setupMocks() {
        activitySummaryManager.activitySummary = .just(nil)
        healthKitManager.shouldRequestReturnValue = .just(false)

        competitionsManager.competitions = .just([.mock, .mockInvited, .mockOld, .mockPublic])
        competitionsManager.standingsPublisherForReturnValue = .just([.mock(for: .evan)])

        friendsManager.friends = .just([.gabby])
        friendsManager.friendRequests = .just([.andrew])
        friendsManager.friendActivitySummaries = .just([User.gabby.id: .mock])

        searchManager.searchForUsersWithIDsReturnValue = .just([.evan])
    }

    static var previews: some View {
        HomeView()
            .setupMocks(setupMocks)
            .embeddedInNavigationView()
    }
}
#endif
