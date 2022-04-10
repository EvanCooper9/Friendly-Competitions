import SwiftUI

struct NewCompetition: View {

    @Environment(\.presentationMode) private var presentationMode
    
    @StateObject private var viewModel = NewCompetitionViewModel()
    
    @State private var presentAddFriends = false

    var body: some View {
        Form {
            details
            scoring
            friendsView

            Section {
                Button("Create") {
                    viewModel.create()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(viewModel.createDisabled)
                .frame(maxWidth: .infinity)
            } footer: {
                Text(viewModel.disabledReason ?? "")
            }
        }
        .navigationTitle("New Competition")
        .embeddedInNavigationView()
        .sheet(isPresented: $presentAddFriends) { AddFriendView() }
        .registerScreenView(name: "New Competition")
    }

    private var details: some View {
        Section {
            TextField("Name", text: $viewModel.name)
            DatePicker(
                "Starts",
                selection: $viewModel.start,
                in: PartialRangeFrom(.now),
                displayedComponents: [.date]
            )
            DatePicker(
                "Ends",
                selection: $viewModel.end,
                in: PartialRangeFrom(viewModel.start.addingTimeInterval(1.days)),
                displayedComponents: [.date]
            )
            Toggle("Repeats", isOn: $viewModel.repeats)
            Toggle("Public", isOn: $viewModel.isPublic)
        } header: {
            Text("Details")
        } footer: {
            if !viewModel.detailsFooterTexts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.detailsFooterTexts, id: \.self) { text in
                        Text(text)
                    }
                }
            }
        }
    }

    private var scoring: some View {
        Section {
            Picker("Scoring model", selection: $viewModel.scoringModel) {
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
                if viewModel.friends.isEmpty {
                    LazyHStack {
                        Text("Nothing here, yet!")
                        Button("Add friends.", toggling: $presentAddFriends)
                    }
                    .padding(.vertical, 6)
                }

                ForEach(viewModel.friends) { friend in
                    HStack {
                        Text(friend.name)
                        Spacer()
                        if viewModel.invitees.contains(friend.id) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.invitees.contains(friend.id) ?
                            viewModel.invitees.remove(friend.id) :
                            viewModel.invitees.append(friend.id)
                    }
                }
            }
        }
    }
}

struct NewCompetitionView_Previews: PreviewProvider {

    private static func setupMocks() {
        friendsManager.friends = [.gabby]
    }

    static var previews: some View {
        NewCompetition()
            .setupMocks(setupMocks)
    }
}
