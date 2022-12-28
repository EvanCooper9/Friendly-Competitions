import Factory
import SwiftUI
import SwiftUIX

struct CompetitionView: View {
    
    @StateObject private var viewModel: CompetitionViewModel

    @State private var canSaveEdits = true
    
    init(competition: Competition) {
        _viewModel = .init(wrappedValue: .init(competition: competition))
    }

    var body: some View {
        List {
            standings
            
            if !viewModel.pendingParticipants.isEmpty {
                pendingInvites
            }
            
            if viewModel.editing {
                EditCompetitionSection(
                    name: $viewModel.competition.name,
                    scoringModel: $viewModel.competition.scoringModel,
                    start: $viewModel.competition.start,
                    end: $viewModel.competition.end,
                    repeats: $viewModel.competition.repeats,
                    isPublic: $viewModel.competition.isPublic
                )
            } else {
                ImmutableListItemView(
                    value: viewModel.competition.start.formatted(date: .abbreviated, time: .omitted),
                    valueType: .date(description: viewModel.competition.started ? "Started" : "Starts")
                )
                ImmutableListItemView(
                    value: viewModel.competition.end.formatted(date: .abbreviated, time: .omitted),
                    valueType: .date(description: viewModel.competition.ended ? "Ended" : "Ends")
                )
                ImmutableListItemView(
                    value: viewModel.competition.scoringModel.displayName,
                    valueType: .other(systemImage: .plusminusCircle, description: "Scoring model")
                )
                if viewModel.competition.repeats {
                    ImmutableListItemView(
                        value: "Yes",
                        valueType: .other(systemImage: .repeatCircle, description: "Restarts")
                    )
                }
            }
            
            actions
        }
        .navigationTitle(viewModel.competition.name)
        .toolbar {
            if viewModel.canEdit {
                HStack {
                    if viewModel.editing {
                        Button("Save", action: viewModel.saveTapped)
                            .disabled(!canSaveEdits)
                    }
                    Button(viewModel.editButtonTitle, action: viewModel.editTapped)
                        .font(viewModel.editing ? .body.bold() : .body)
                }
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
    }

    private var standings: some View {
        Section {
            ForEach(viewModel.standings) {
                CompetitionParticipantRow(config: $0)
            }
        } header: {
            Text("Standings")
        } footer: {
            if viewModel.standings.isEmpty {
                Text("Nothing here, yet.")
            }
        }
    }

    private var pendingInvites: some View {
        Section("Pending invites") {
            ForEach(viewModel.pendingParticipants) {
                CompetitionParticipantRow(config: $0)
            }
        }
    }

    private var actions: some View {
        Section {
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
            Button("Yes", role: .destructive, action: viewModel.confirm)
            Button("Cancel", role: .cancel) {}
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
        let standings: [Competition.ID: [Competition.Standing]] = [
            competition.id: [
                .init(rank: 1, userId: "Somebody", points: 100),
                .init(rank: 2, userId: "Rick", points: 75),
                .init(rank: 3, userId: "Bob", points: 60),
                .init(rank: 4, userId: gabby.id, points: 50),
                .init(rank: 5, userId: evan.id, points: 20),
                .init(rank: 6, userId: "Joe", points: 9),
            ]
        ]
        let participants: [Competition.ID: [User]] = [
            competition.id: [evan, gabby]
        ]
        let pendingParticipants: [Competition.ID: [User]] = [
            competition.id: [gabby]
        ]
        competitionsManager.competitions = .just([competition])
        competitionsManager.standings = .just(standings)
        competitionsManager.participants = .just(participants)
        competitionsManager.pendingParticipants = .just(pendingParticipants)
    }

    static var previews: some View {
        CompetitionView(competition: competition)
            .embeddedInNavigationView()
            .setupMocks(setupMocks)
    }
}
#endif
