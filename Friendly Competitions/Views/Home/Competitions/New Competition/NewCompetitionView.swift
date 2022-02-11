import SwiftUI

struct NewCompetitionView: View {

    @State private var editorConfig = NewCompetitionEditorConfig()

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var competitionManager: AnyCompetitionsManager
    @EnvironmentObject private var friendsManager: AnyFriendsManager
    @EnvironmentObject private var user: User
    @State private var presentAddFriends = false

    var body: some View {
        Form {
            details
            scoring
            friendsView

            Section {
                Button("Create") {
                    let newCompetition = editorConfig.competition(creator: user)
                    competitionManager.create(newCompetition)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(editorConfig.createDisabled)
                .frame(maxWidth: .infinity)
            } footer: {
                Text(editorConfig.disabledReason ?? "")
            }
        }
        .navigationTitle("New Competition")
        .embeddedInNavigationView()
        .sheet(isPresented: $presentAddFriends) { AddFriendView() }
    }

    private var details: some View {
        Section("Details") {
            TextField("Name", text: $editorConfig.name)
            DatePicker(
                "Starts",
                selection: $editorConfig.start,
                in: dateRange(startingFrom: editorConfig.start),
                displayedComponents: [.date]
            )
            DatePicker(
                "Ends",
                selection: $editorConfig.end,
                in: dateRange(startingFrom: editorConfig.start),
                displayedComponents: [.date]
            )
        }
    }

    private var scoring: some View {
        Section {
            Picker("Scoring model", selection: $editorConfig.scoringModel) {
                ForEach(Competition.ScoringModel.allCases) { scoringModel in
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
                        ForEach(Competition.ScoringModel.allCases) { scoringModel in
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
                        if editorConfig.invitees.contains(friend.id) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editorConfig.invitees.contains(friend.id) ?
                            editorConfig.invitees.remove(friend.id) :
                            editorConfig.invitees.append(friend.id)
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
