import SwiftUI

struct NewCompetition: View {

    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject private var competitionManager: AnyCompetitionsManager
    @EnvironmentObject private var friendsManager: AnyFriendsManager
    @EnvironmentObject private var userManager: AnyUserManager
    
    @State private var editorConfig = NewCompetitionEditorConfig()
    @State private var presentAddFriends = false

    var body: some View {
        Form {
            details
            scoring
            friendsView

            Section {
                Button("Create") {
                    competitionManager.createCompetition(with: editorConfig)
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
        .registerScreenView(name: "New Competition")
    }

    private var details: some View {
        Section {
            TextField("Name", text: $editorConfig.name)
            DatePicker(
                "Starts",
                selection: $editorConfig.start,
                in: PartialRangeFrom(.now),
                displayedComponents: [.date]
            )
            DatePicker(
                "Ends",
                selection: $editorConfig.end,
                in: PartialRangeFrom(editorConfig.start.addingTimeInterval(1.days)),
                displayedComponents: [.date]
            )
            Toggle("Repeats", isOn: $editorConfig.repeats)
            Toggle("Public", isOn: $editorConfig.isPublic)
        } header: {
            Text("Details")
        } footer: {
            if !editorConfig.detailsFooterTexts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(editorConfig.detailsFooterTexts, id: \.self) { text in
                        Text(text)
                    }
                }
            }
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
}

struct NewCompetitionView_Previews: PreviewProvider {

    private static func setupMocks() {
//        friendsManager.friends = [.gabby]
    }

    static var previews: some View {
        NewCompetition()
            .setupMocks(setupMocks)
    }
}
