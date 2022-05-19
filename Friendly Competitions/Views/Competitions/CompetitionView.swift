import SwiftUI
import SwiftUIX

struct CompetitionView: View {
    
    @StateObject private var viewModel: CompetitionViewModel

    @State private var showInviteFriend = false
    
    init(competition: Competition) {
        _viewModel = .init(wrappedValue: CompetitionViewModel(competition: competition))
    }

    var body: some View {
        List {
            standings
            if !viewModel.pendingParticipants.isEmpty {
                pendingInvites
            }
            CompetitionInfo(competition: $viewModel.competition, editing: viewModel.editing)
            actions
        }
        .navigationTitle(viewModel.competition.name)
        .toolbar {
            if viewModel.canEdit {
                HStack {
                    if viewModel.editing {
                        Button("Save", action: viewModel.saveTapped)
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
    }

    private var standings: some View {
        Section {
            ForEach(viewModel.standings) {
                CompetitionParticipantView(config: $0)
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
                CompetitionParticipantView(config: $0)
            }
        }
    }

    private var actions: some View {
        Section {
            if viewModel.showInviteButton {
                Button("Invite a friend", systemImage: .personCropCircleBadgePlus) { showInviteFriend.toggle() }
            }
            if viewModel.showJoinButton {
                Button("Join competition", systemImage: .personCropCircleBadgeCheckmark, action: viewModel.join)
            }
            if viewModel.showLeaveButton {
                Button("Leave competition", systemImage: .personCropCircleBadgeMinus, action: viewModel.leaveTapped)
                    .foregroundColor(.red)
            }
            if viewModel.showDeleteButton {
                Button("Delete competition", systemImage: .trash, action: viewModel.deleteTapped)
                    .foregroundColor(.red)
            }
            if viewModel.showInvitedButtons {
                Button("Accept invite", systemImage: .personCropCircleBadgeCheckmark, action: viewModel.accept)
                Button("Decline invite", systemImage: .personCropCircleBadgeXmark, action: viewModel.decline)
                    .foregroundColor(.red)
            }
        }
        .confirmationDialog(viewModel.confirmationTitle, isPresented: $viewModel.confirmationRequired, titleVisibility: .visible) {
            Button("Yes", role: .destructive, action: viewModel.confirm)
            Button("Cancel", role: .cancel, action: viewModel.retract)
        }
        .sheet(isPresented: $showInviteFriend) {
            InviteFriends(action: .competitionInvite(viewModel.competition))
        }
    }
}

struct CompetitionView_Previews: PreviewProvider {

    private static let competition = Competition.mock

    private static func setupMocks() {
        let evan = User.evan
        let gabby = User.gabby
        competitionsManager.standings = [
            competition.id: [
                .init(rank: 1, userId: "Somebody", points: 100),
                .init(rank: 2, userId: "Rick", points: 75),
                .init(rank: 3, userId: "Bob", points: 60),
                .init(rank: 4, userId: gabby.id, points: 50),
                .init(rank: 5, userId: evan.id, points: 20),
                .init(rank: 6, userId: "Joe", points: 9),
            ]
        ]
        competitionsManager.participants = [
            competition.id: [evan, gabby]
        ]
        competitionsManager.pendingParticipants = [
            competition.id: [gabby]
        ]
    }

    static var previews: some View {
        CompetitionView(competition: competition)
            .setupMocks(setupMocks)
            .embeddedInNavigationView()
    }
}
