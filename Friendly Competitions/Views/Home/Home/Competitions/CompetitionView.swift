import SwiftUI

struct CompetitionView: View {

    @Binding var competition: Competition

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager
    @EnvironmentObject private var friendsManager: AnyFriendsManager
    @EnvironmentObject private var userManager: AnyUserManager

    private enum Action {
        case leave, delete
    }

    @State private var showAreYouSure = false
    @State private var actionRequiringConfirmation: Action?
    @State private var showInviteFriend = false

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
    }

    @ViewBuilder
    private var standings: some View {
        let standings = competitionsManager.standings[competition.id] ?? []
        Section {
            ForEach(standings) { standing in
                HStack {
                    Text(standing.rank.ordinalString ?? "?").bold()
                    if let user = competitionsManager.participants[competition.id]?.first(where: { $0.id == standing.userId }) {
                        Text(user.name)
                        UserHashIDPill(user: user)
                    } else {
                        Text(standing.userId)
                    }
                    Spacer()
                    Text("\(standing.points)")
                }
                .foregroundColor(standing.userId == userManager.user.id ? .blue : nil)
            }
        } header: {
            Text("Standings")
        } footer: {
            if standings.isEmpty {
                Text("Nothing here, yet.")
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

            if competition.participants.contains(userManager.user.id) {
                Button("Leave competition", systemImage: "person.crop.circle.badge.minus") {
                    actionRequiringConfirmation = .leave
                }
                .foregroundColor(.red)

                if competition.owner == userManager.user.id {
                    Button("Delete competition", systemImage: "trash") {
                        actionRequiringConfirmation = .delete
                    }
                    .foregroundColor(.red)
                }
            } else if competition.pendingParticipants.contains(userManager.user.id) {
                Button("Accept invite", systemImage: "person.crop.circle.badge.checkmark") {
                    competitionsManager.accept(competition)
                }
                Button("Decline invite", systemImage: "person.crop.circle.badge.xmark") {
                    competitionsManager.decline(competition)
                }
                .foregroundColor(.red)
            } else {
                Button("Join competition", systemImage: "person.crop.circle.badge.checkmark") {
                    competitionsManager.join(competition)
                }
            }
        }
        .confirmationDialog(
            "Are you sure?",
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
                Section {
                    ForEach(friendsManager.friends) { friend in
                        AddFriendListItem(
                            friend: friend,
                            action: .competitionInvite,
                            disabledIf: competition.pendingParticipants.contains(friend.id) || competition.participants.contains(friend.id)
                        ) { competitionsManager.invite(friend, to: competition) }
                    }
                } footer: {
                    Text("Friends who join in-progress competitions will have their scores from missed days retroactively uploaded.")
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
                .init(rank: 1, userId: "1", points: 100),
                .init(rank: 2, userId: "2", points: 50),
                .init(rank: 3, userId: "a", points: 50),
                .init(rank: 4, userId: "b", points: 50),
//                .init(rank: 5, userId: "c", points: 50),
                .init(rank: 5, userId: evan.id, points: 50),
                .init(rank: 6, userId: "d", points: 50),
//                .init(rank: 7, userId: "e", points: 50),
//                .init(rank: 8, userId: "f", points: 50),
//                .init(rank: 9, userId: "g", points: 50),
//                .init(rank: 10, userId: "h", points: 50)
            ]
        ]
        competitionManager.participants = [
            competition.id: [.evan, .gabby]
        ]
        competitionManager.pendingParticipants = [
            competition.id: [.gabby]
        ]

        return competitionManager
    }()

    private static let friendsManager: AnyFriendsManager = {
        let friendsManager = AnyFriendsManager()
        friendsManager.searchResults = [.gabby]
        return friendsManager
    }()

    private static let userManager: AnyUserManager = {
        AnyUserManager(user: .evan)
    }()

    static var previews: some View {
        CompetitionView(competition: .constant(competition))
            .environmentObject(competitionManager)
            .environmentObject(friendsManager)
            .environmentObject(userManager)
            .embeddedInNavigationView()
    }
}