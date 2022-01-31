import SwiftUI

struct NewCompetitionView: View {

    @State private var competition = Competition()

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var competitionManager: AnyCompetitionsManager
    @EnvironmentObject private var friendsManager: AnyFriendsManager
    @EnvironmentObject private var user: User
    @State private var presentAddFriends = false

    private var createDisabled: Bool {
        competition.name.isEmpty || competition.pendingParticipants.isEmpty
    }

    private var disabledReason: String? {
        if competition.name.isEmpty {
            return "Please enter a name"
        } else if competition.pendingParticipants.isEmpty {
            return "Please invite friends"
        }
        return nil
    }

    var body: some View {
        Form {
            details
            scoring
            friendsView

            Section {
                Button("Create") {
                    competition.participants.append(user.id)
                    competitionManager.create(competition)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(createDisabled)
                .frame(maxWidth: .infinity)
            } footer: {
                Text(disabledReason ?? "")
            }
        }
        .navigationTitle("New Competition")
        .embeddedInNavigationView()
        .sheet(isPresented: $presentAddFriends) { AddFriendView() }
    }

    private var details: some View {
        Section("Details") {
            TextField("Name", text: $competition.name)
            DatePicker(
                "Starts",
                selection: $competition.start,
                in: dateRange(startingFrom: .now.addingTimeInterval(-7.days)),
                displayedComponents: [.date]
            )
            DatePicker(
                "Ends",
                selection: $competition.end,
                in: dateRange(startingFrom: competition.end),
                displayedComponents: [.date]
            )
        }
    }

    private var scoring: some View {
        Section {
            Picker("Scoring model", selection: $competition.scoringModel) {
                ForEach(ScoringModel.allCases) { scoringModel in
                    Text(scoringModel.displayName)
                        .tag(scoringModel)
                }
            }
        } header: {
            Text("Scoring")
        } footer: {
            NavigationLink("What's this?") {
                List {
                    Section {
                        ForEach(ScoringModel.allCases) { scoringModel in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(scoringModel.displayName)
                                    .font(.title3)
                                Text(scoringModel.description)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                    } footer: {
                        Text("Scoring models will affect how scores are calculated")
                    }
                }
                .navigationTitle("Scoring models")
            }
        }
    }

    private var friendsView: some View {
        Section("Invite friends") {
            List {
                if friendsManager.friends.isEmpty {
                    LazyHStack {
                        Text("Nothing here, yet!")
                        Button("Add friends.", toggling: $presentAddFriends)
                    }
                    .padding(.vertical, 6)
                }

                ForEach(friendsManager.friends) { friend in
                    HStack {
                        Text(friend.name)
                        Spacer()
                        if competition.pendingParticipants.contains(friend.id) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        competition.pendingParticipants.contains(friend.id) ?
                            competition.pendingParticipants.remove(friend.id) :
                            competition.pendingParticipants.append(friend.id)
                    }
                }
            }
        }
    }

    private func dateRange(startingFrom date: Date) -> PartialRangeFrom<Date> {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return PartialRangeFrom<Date>(Calendar.current.date(from: components)!)
    }
}

struct NewCompetitionView_Previews: PreviewProvider {

    private static let competitionsManager = AnyCompetitionsManager()
    private static let friendsManager: AnyFriendsManager = {
        let friendsManager = AnyFriendsManager()
        friendsManager.friends = [.gabby]
        return friendsManager
    }()

    static var previews: some View {
        NewCompetitionView()
            .environmentObject(competitionsManager)
            .environmentObject(friendsManager)
    }
}
