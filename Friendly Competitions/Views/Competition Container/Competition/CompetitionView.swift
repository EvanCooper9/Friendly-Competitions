import ECKit
import Factory
import SwiftUI
import SwiftUIX

struct CompetitionView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CompetitionViewModel

    init(competition: Competition) {
        _viewModel = .init(wrappedValue: .init(competition: competition))
    }

    var body: some View {
        CustomList {
            if viewModel.banners.isNotEmpty {
                ItemStack(models: viewModel.banners) { banner in
                    banner.view {
                        viewModel.tapped(banner: banner)
                    }
                }
                .padding(.horizontal)
            }

            standings

            CustomListSection {
                ForEach(viewModel.details, id: \.value) { detail in
                    ImmutableListItemView(value: detail.value, valueType: detail.valueType)
                }
            } header: {
                Text("Details")
            }

            actions
        }
        .background(.secondarySystemBackground)
        .navigationTitle(viewModel.competition.name)
        .toolbar {
            if viewModel.canEdit {
                Button(L10n.Competition.Action.Edit.buttonTitle, action: viewModel.editTapped)
            }
        }
        .registerScreenView(
            name: "Competition",
            parameters: [
                "id": viewModel.competition.id,
                "name": viewModel.competition.name
            ]
        )
        .withLoadingOverlay(isLoading: viewModel.loading)
        .animation(.default, value: viewModel.banners)
        .sheet(isPresented: $viewModel.editing) {
            CompetitionEditView(competition: viewModel.competition)
        }
        .onChange(of: viewModel.dismiss) { _ in dismiss() }
    }

    private var standings: some View {
        CustomListSection {
            if viewModel.loadingStandings {
                ProgressView()
            } else {
                ForEach(viewModel.standings) { config in
                    CompetitionParticipantRow(config: config)
                }
                if viewModel.showShowMoreButton {
                    Button(L10n.Competition.Standings.showMore, action: viewModel.showMoreTapped)
                }
            }
        } header: {
            Text(L10n.Competition.Standings.title)
        } footer: {
            if viewModel.standings.isEmpty && !viewModel.loadingStandings {
                Text(L10n.Competition.Standings.empty)
            }
        }
    }

    private var actions: some View {
        CustomListSection {
            ForEach(viewModel.actions, id: \.self) { action in
                Button {
                    viewModel.perform(action)
                } label: {
                    Label(action.buttonTitle, systemImage: action.systemImage)
                        .if(action.destructive) { view in
                            view.foregroundColor(.red)
                        }
                }
            }
        }
        .confirmationDialog(viewModel.confirmationTitle, isPresented: $viewModel.confirmationRequired, titleVisibility: .visible) {
            Button(L10n.Generics.yes, role: .destructive, action: viewModel.confirm)
            Button(L10n.Generics.cancel, role: .cancel) {}
        }
        .sheet(isPresented: $viewModel.showInviteFriend) {
            InviteFriendsView(action: .competitionInvite(viewModel.competition))
        }
    }
}

#if DEBUG
struct CompetitionView_Previews: PreviewProvider {

    private static let competition = Competition.mock

    private static func setupMocks() {
        let evan = User.evan
        let gabby = User.gabby
        let standings: [Competition.Standing] = [
            .init(rank: 1, userId: "Somebody", points: 100),
            .init(rank: 2, userId: "Rick", points: 75),
            .init(rank: 3, userId: "Bob", points: 60),
            .init(rank: 4, userId: gabby.id, points: 50),
            .init(rank: 5, userId: evan.id, points: 20),
            .init(rank: 6, userId: "Joe", points: 9)
        ]
        let participants = [evan, gabby]
        competitionsManager.competitions = .just([competition])
        competitionsManager.competitionPublisherForReturnValue = .just(competition)
        competitionsManager.standingsPublisherForReturnValue = .just(standings)

        healthKitManager.shouldRequestReturnValue = .just(true)
        notificationsManager.permissionStatusReturnValue = .just(.notDetermined)

        searchManager.searchForUsersWithIDsReturnValue = .just(participants)
    }

    static var previews: some View {
        CompetitionView(competition: competition)
            .embeddedInNavigationView()
            .setupMocks(setupMocks)
    }
}
#endif
