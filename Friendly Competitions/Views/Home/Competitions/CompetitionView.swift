import FirebaseFirestore
import Resolver
import SwiftUI

struct CompetitionView: View {

    let competition: Competition

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager
    @EnvironmentObject private var friendsManager: AnyFriendsManager
    @EnvironmentObject private var user: User

    private enum Action {
        case leave, delete
    }
    @State private var showAreYouSure = false
    @State private var actionRequiringConfirmation: Action?
    @State private var showInviteFriend = false

    var body: some View {
        VStack {
            List {
                standings
                if !competition.pendingParticipants.isEmpty {
                    pendingInvites
                }
                details
                actions
            }
        }
        .navigationTitle(competition.name)
    }

    private var standings: some View {
        Section("Standings") {
            ForEach(competitionsManager.standings[competition.id] ?? []) { standing in
                HStack {
                    Text(standing.rank.ordinalString ?? "?").bold()
                    if let participant = competitionsManager.participants[competition.id]?.first(where: { $0.id == standing.userId }) {
                        Text(participant.name)
                    } else {
                        Text(standing.userId)
                    }
//                    Text(competitionsManager.participants.first(where: { $0.id == standing.userId })?.name ?? standing.userId)
                    Spacer()
                    Text("\(standing.points)")
                }
            }
        }
    }

    private var pendingInvites: some View {
        Section("Pending invites") {
            ForEach(competitionsManager.pendingParticipants[competition.id] ?? []) {
                Text($0.name)
            }
        }
    }

    private var details: some View {
        Section("Details") {
            ImmutableListItemView(
                value: competition.start.formatted(date: .complete, time: .omitted),
                valueType: .date(description: competition.started ? "Started" : "Starts")
            )
            ImmutableListItemView(
                value: competition.end.formatted(date: .complete, time: .omitted),
                valueType: .date(description: competition.ended ? "Ended" : "Ends")
            )
            ImmutableListItemView(
                value: competition.scoringModel.displayName,
                valueType: .other(systemImage: "plusminus.circle", description: "Scoring model")
            )
        }
    }

    private var actions: some View {
        Section {
            if competition.pendingParticipants.contains(user.id) {
                Button("Accept invite") {
                    competitionsManager.accept(competition)
                }
                Button("Decline invite") {
                    competitionsManager.decline(competition)
                }
                .foregroundColor(.red)
            } else {
                Button(toggling: $showInviteFriend) {
                    Label("Invite a friend", systemImage: "person.crop.circle.badge.plus")
                }
                Button {
                    actionRequiringConfirmation = .leave
                } label: {
                    Label("Leave competition", systemImage: "person.crop.circle.badge.minus")
                        .foregroundColor(.red)
                }
                Button {
                    actionRequiringConfirmation = .delete
                } label: {
                    Label("Delete competition", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .confirmationDialog(
            "Are you sure? This cannot be undone.",
            isPresented: .isNotNil($actionRequiringConfirmation),
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive) {
                guard let actionRequiringConfirmation = actionRequiringConfirmation else { return }
                switch actionRequiringConfirmation {
                case .leave:
                    competitionsManager.leave(competition)
                case .delete:
                    competitionsManager.delete(competition)
                }
                self.actionRequiringConfirmation = nil
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {
                actionRequiringConfirmation = nil
            }
        }
        .sheet(isPresented: $showInviteFriend) {
            List {
                ForEach(friendsManager.friends) { friend in
                    AddFriendListItem(
                        friend: friend,
                        action: .competitionInvite,
                        disabledIf: competition.pendingParticipants.contains(friend.id)
                    ) { competitionsManager.invite(friend, to: competition) }
                }
            }
            .navigationTitle("Invite a friend")
            .embeddedInNavigationView()
        }
    }
}

extension Binding {
    static func isNotNil<T>(_ binding: Binding<T?>) -> Binding<Bool> {
        .init {
            binding.wrappedValue != nil
        } set: { b in
            // do nothing
        }
    }
}

struct CompetitionView_Previews: PreviewProvider {

    private static let competition = Competition.mock
    private static let competitionManager: AnyCompetitionsManager = {
        let evan = User.evan
        let gabby = User.gabby
        let competitionManager = AnyCompetitionsManager()
        competitionManager.competitions = [competition]
        competitionManager.standings = [
            competition.id: [
                .init(rank: 1, userId: evan.id, points: 100),
                .init(rank: 2, userId: gabby.id, points: 50)
            ]
        ]
        competitionManager.participants = [
            competition.id: [
                .init(from: evan),
                .init(from: gabby)
            ]
        ]
        competitionManager.pendingParticipants = [
            competition.id: [
                .init(from: gabby)
            ]
        ]

        return competitionManager
    }()

    static var previews: some View {
        CompetitionView(competition: competition)
            .environmentObject(User.evan)
            .environmentObject(competitionManager)
            .embeddedInNavigationView()
        CompetitionView(competition: .mockInvited)
            .environmentObject(User.evan)
            .environmentObject(competitionManager)
            .embeddedInNavigationView()
    }
}
