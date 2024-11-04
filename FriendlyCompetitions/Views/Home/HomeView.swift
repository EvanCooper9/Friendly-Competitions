import ECKit
import SwiftUI
import SwiftUIX

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        CustomList {
            if viewModel.banners.isNotEmpty {
                banners
            }

            activity
            competitions
            friends

            if let unit = viewModel.googleAdUnit {
                ad(unit: unit)
            }
        }
        .navigationBarTitle(L10n.Home.title)
        .toolbar {
            ToolbarItemGroup {
                if viewModel.showDeveloper {
                    DeveloperMenu()
                }

                Button(action: viewModel.notificationsTapped) {
                    Image(systemName: viewModel.hasNotifications ? .bellCircleFill : .bellCircle)
                        .foregroundStyle(viewModel.hasNotifications ? .red : Color.accentColor)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAnonymousAccountBlocker, content: CreateAccountView.init)
        .sheet(isPresented: $viewModel.showNewCompetition) { CompetitionEditView(competition: nil) }
        .sheet(isPresented: $viewModel.showAddFriends) { InviteFriendsView(action: .addFriend) }
        .sheet(isPresented: $viewModel.showNotifications) { NotificationsView() }
        .sheet(item: $viewModel.deepLinkedNavigationDestination) { $0.view.embeddedInNavigationView() }
        .withLoadingOverlay(isLoading: viewModel.loadingDeepLink)
        .navigationDestination(for: NavigationDestination.self) { $0.view }
        .embeddedInNavigationStack(path: $viewModel.navigationDestinations)
        .registerScreenView(name: "Home")
    }

    private var banners: some View {
        ItemStack(models: viewModel.banners) { banner in
            Swipeable {
                banner.view {
                    viewModel.tapped(banner)
                }
            } onDelete: {
                viewModel.dismissed(banner)
            }
        }
        .padding(.horizontal)
    }

    private var activity: some View {
        CustomListSection {
            ActivitySummaryInfoView(source: .local)
            HStack {
                Text(L10n.Home.Section.Activity.Steps.steps)
                Spacer()
                switch viewModel.steps {
                case .value(let steps):
                    Text(steps.formatted())
                        .monospaced()
                        .foregroundStyle(.secondary)
                case .requiresPermission:
                    Button(L10n.Home.Section.Activity.Steps.request, action: viewModel.requestPermissionsForSteps)
                        .buttonStyle(.borderedProminent)
                }
            }
        } header: {
            Text(L10n.Home.Section.Activity.title)
                .foregroundStyle(.secondary)
        }
    }

    private var competitions: some View {
        CustomListSection {
            if viewModel.competitions.isEmpty && viewModel.invitedCompetitions.isEmpty {
                HomeViewEmptyContent(
                    symbol: "trophy.fill",
                    message: L10n.Home.Section.Competitions.Empty.message,
                    buttons: [
                        .init(title: L10n.Home.Section.Competitions.Empty.create, action: viewModel.newCompetitionTapped),
                        .init(title: L10n.Home.Section.Competitions.Empty.explore, action: viewModel.exploreCompetitionsTapped)
                    ]
                )
            } else {
                ForEach(viewModel.competitions + viewModel.invitedCompetitions) { competition in
                    NavigationLink(value: NavigationDestination.competition(competition, nil)) {
                        CompetitionDetails(competition: competition, showParticipantCount: false, isFeatured: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            HStack(alignment: .bottom) {
                Text(L10n.Home.Section.Competitions.title)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(systemImage: .plusCircle, action: viewModel.newCompetitionTapped)
                    .font(.title2)
            }
        }
    }

    private var friends: some View {
        CustomListSection {
            if viewModel.friendRows.isEmpty {
                HomeViewEmptyContent(
                    symbol: "person.3.fill",
                    message: L10n.Home.Section.Friends.Empty.message,
                    buttons: [.init(title: L10n.Home.Section.Friends.Empty.add, action: viewModel.addFriendsTapped)]
                )
            } else {
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
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            HStack(alignment: .bottom) {
                Text(L10n.Home.Section.Friends.title)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(systemImage: .personCropCircleBadgePlus, action: viewModel.addFriendsTapped)
                    .font(.title2)
            }
        }
    }

    private func ad(unit: GoogleAdUnit) -> some View {
        GoogleAd(unit: unit)
            .padding(.horizontal)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {

    private static func setupMocks() {
        activitySummaryManager.activitySummary = .just(nil)
        backgroundRefreshManager.status = .just(.denied)
        bannerManager.banners = .just([.competitionResultsCalculating(competition: .mock)])
        healthKitManager.shouldRequestReturnValue = .just(false)

        competitionsManager.competitions = .just([.mockOld, .mockPublic])
        competitionsManager.standingsPublisherForLimitReturnValue = .just([.mock(for: .evan)])
        competitionsManager.unseenResults = .just([])

        friendsManager.friends = .just([.gabby])
        friendsManager.friendRequests = .just([.andrew])
        friendsManager.friendActivitySummaries = .just([User.gabby.id: .mock])

        searchManager.searchForUsersWithIDsReturnValue = .just([.evan])

        stepCountManager.stepCountsInReturnValue = .just([.init(count: 12345, date: .now)])

        notificationsManager.permissionStatusReturnValue = .just(.notDetermined)
    }

    static var previews: some View {
        HomeView()
            .setupMocks(setupMocks)
            .embeddedInNavigationView()
    }
}
#endif
