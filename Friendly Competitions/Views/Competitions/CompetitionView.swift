import SwiftUI

struct CompetitionView: View {
    
    let competition: Competition

    @Environment(\.presentationMode) private var presentationMode
    
    @StateObject private var viewModel: CompetitionViewModel

    private enum Action {
        case leave, delete
    }

    @State private var actionRequiringConfirmation: Action?
    @State private var showInviteFriend = false
    
    init(competition: Competition) {
        _viewModel = .init(wrappedValue: CompetitionViewModel(competition: competition))
        self.competition = competition
    }

    var body: some View {
        List {
            standings
            if !competition.pendingParticipants.isEmpty {
                pendingInvites
            }
            details
            actions
        }
        .navigationTitle(competition.name)
        .registerScreenView(
            name: "Competition",
            parameters: [
                "id": competition.id,
                "name": competition.name
            ]
        )
    }

    @ViewBuilder
    private var standings: some View {
        Section {
            ForEach(viewModel.standings) { standing in
                HStack {
                    Text(standing.rank).bold()
                    Text(standing.name)
                        .blur(radius: standing.blurred ? 5 : 0)
//                    UserHashIDPill(user: userManager.user)
                    Spacer()
                    Text(standing.points)
                }
                .foregroundColor(standing.highlighted ? .blue : nil)
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
                Text($0.name)
            }
        }
    }

    private var details: some View {
        Section("Details") {
            ImmutableListItemView(
                value: competition.start.formatted(date: .abbreviated, time: .omitted),
                valueType: .date(description: competition.started ? "Started" : "Starts")
            )
            ImmutableListItemView(
                value: competition.end.formatted(date: .abbreviated, time: .omitted),
                valueType: .date(description: competition.ended ? "Ended" : "Ends")
            )
            ImmutableListItemView(
                value: competition.scoringModel.displayName,
                valueType: .other(systemImage: "plusminus.circle", description: "Scoring model")
            )
            if competition.repeats {
                ImmutableListItemView(
                    value: "Yes",
                    valueType: .other(systemImage: "repeat.circle", description: "Restarts")
                )
            }
        }
    }

    private var actions: some View {
        Section {
            if !competition.ended {
                Button("Invite a friend", systemImage: "person.crop.circle.badge.plus") {
                    showInviteFriend.toggle()
                }
            }

            if competition.participants.contains(viewModel.user.id) {
                Button("Leave competition", systemImage: "person.crop.circle.badge.minus") {
                    actionRequiringConfirmation = .leave
                }
                .foregroundColor(.red)

                if competition.owner == viewModel.user.id {
                    Button("Delete competition", systemImage: "trash") {
                        actionRequiringConfirmation = .delete
                    }
                    .foregroundColor(.red)
                }
            } else if competition.pendingParticipants.contains(viewModel.user.id) {
                Button("Accept invite", systemImage: "person.crop.circle.badge.checkmark") {
                    viewModel.accept(competition)
                }
                Button("Decline invite", systemImage: "person.crop.circle.badge.xmark") {
                    viewModel.decline(competition)
                }
                .foregroundColor(.red)
            } else {
                Button("Join competition", systemImage: "person.crop.circle.badge.checkmark") {
                    viewModel.join(competition)
                }
            }
        }
        .confirmationDialog(
            "Are your sure",
            presenting: $actionRequiringConfirmation,
            titleVisibility: .visible
        ) { action in
            Button("Yes", role: .destructive) {
                switch action {
                case .leave:
                    viewModel.leave(competition)
                case .delete:
                    viewModel.delete(competition)
                }
                presentationMode.wrappedValue.dismiss()
                actionRequiringConfirmation = nil
            }
            Button("Cancel", role: .cancel) { actionRequiringConfirmation = nil }
        }
        .sheet(isPresented: $showInviteFriend) {
//            List {
//                Section {
//                    ForEach(friendsManager.friends) { friend in
//                        AddFriendListItem(
//                            friend: friend,
//                            action: .competitionInvite,
//                            disabledIf: competition.pendingParticipants.contains(friend.id) || competition.participants.contains(friend.id)
//                        ) { competitionsManager.invite(friend, to: competition) }
//                    }
//                } footer: {
//                    Text("Friends who join in-progress competitions will have their scores from missed days retroactively uploaded.")
//                }
//            }
//            .navigationTitle("Invite a friend")
//            .embeddedInNavigationView()
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
