import SwiftUI

struct NewCompetitionView: View {

    @State private var editorConfig = NewCompetitionEditorConfig()

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var competitionManager: AnyCompetitionsManager
    @EnvironmentObject private var friendsManager: AnyFriendsManager
    @EnvironmentObject private var profanityManager: AnyProfanityManager
    @EnvironmentObject private var userManager: AnyUserManager
    @State private var presentAddFriends = false

    @State private var error: Error?

    var body: some View {
        Form {
            details
            scoring
            friendsView

            Section {
                Button("Create", action: createCompetition)
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
        Section {
            HStack {
                TextField("Name", text: $editorConfig.name)
                    .onChange(of: editorConfig.name) { newValue in
                        Task {
                            do {
                                try await profanityManager.checkProfanity(newValue)
                                DispatchQueue.main.async {
                                    error = nil
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.error = error
                                }
                            }
                        }
                    }
                if let error = error {
                    Text(error.localizedDescription)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
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

    private func dateRange(startingFrom date: Date) -> PartialRangeFrom<Date> {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return PartialRangeFrom<Date>(Calendar.current.date(from: components)!)
    }

    private func createCompetition() {
        Task {
            do {
                try await competitionManager.createCompetition(with: editorConfig)
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    withAnimation {
                        self.error = error
                    }
                }
            }
        }
    }
}

struct NewCompetitionView_Previews: PreviewProvider {

    private static let competitionsManager = AnyCompetitionsManager()
    private static let friendsManager: AnyFriendsManager = {
        let friendsManager = AnyFriendsManager()
        friendsManager.friends = [.gabby]
        return friendsManager
    }()

    private static let userManager: AnyUserManager = {
        AnyUserManager(user: .evan)
    }()

    static var previews: some View {
        NewCompetitionView()
            .environmentObject(competitionsManager)
            .environmentObject(friendsManager)
            .environmentObject(userManager)
    }
}
