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
                            Button(L10n.Home.Section.Activity.Steps.request, action: viewModel.tappedStepsButton)
                                .buttonStyle(.borderedProminent)
                        }
                    }
                } header: {
                    Text(L10n.Home.Section.Activity.title)
                }

                if viewModel.competitions.isNotEmpty {
                    competitions
                    friends
                } else if viewModel.friendRows.isNotEmpty {
                    friends
                    competitions
                } else {
                    competitions
                    friends
                }

                if let unit = viewModel.googleAdUnit {
                    GoogleAd(unit: unit)
                        .padding()
                }
            }
            .navigationBarTitle(L10n.Home.title)
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
            .sheet(isPresented: $viewModel.showNewCompetition) { CompetitionEditView(competition: nil) }
            .sheet(isPresented: $viewModel.showAddFriends) { InviteFriendsView(action: .addFriend) }
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

    private var competitions: some View {
        CustomListSection {
            if viewModel.competitions.isEmpty && viewModel.invitedCompetitions.isEmpty {
                emptyContent(
                    title: L10n.Home.Section.Competitions.title,
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
                emptyContent(
                    title: L10n.Home.Section.Friends.title,
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

    private struct EmptyContentButtonConfiguration: Identifiable {
        var id: String { title }
        let title: String
        let action: () -> Void
    }

    private func emptyContent(title: String, symbol: String, message: String, buttons: [EmptyContentButtonConfiguration]) -> some View {
        VStack(alignment: .center, spacing: 20) {
            Image(systemName: symbol)
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .scaledToFit()
                .height(75)
                .foregroundStyle(.secondary)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                ForEach(enumerating: buttons) { index, button in
                    let button = Button(button.title, action: button.action)
                    switch index {
                    case 0:
                        button.buttonStyle(.borderedProminent)
                    case 1:
                        button.buttonStyle(.bordered)
                    default:
                        button
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {

    private static func setupMocks() {
        activitySummaryManager.activitySummary = .just(nil)
        healthKitManager.shouldRequestReturnValue = .just(false)

//        competitionsManager.competitions = .just([.mockOld, .mockPublic])
//        competitionsManager.standingsPublisherForLimitReturnValue = .just([.mock(for: .evan)])
        competitionsManager.unseenResults = .just([])

//        friendsManager.friends = .just([.gabby])
//        friendsManager.friendRequests = .just([.andrew])
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
