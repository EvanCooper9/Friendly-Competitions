import SwiftUI
import HealthKit

struct NewCompetition: View {

    @Environment(\.presentationMode) private var presentationMode
    
    @StateObject private var viewModel = NewCompetitionViewModel()
    
    @State private var presentAddFriends = false

    var body: some View {
        Form {
            CompetitionInfo(competition: $viewModel.competition, editing: true)
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
        .sheet(isPresented: $presentAddFriends) { InviteFriends(action: .addFriend) }
        .registerScreenView(name: "New Competition")
    }
    
    private var scoring: some View {
        Section {
            Toggle("Constrain to workout", isOn: $viewModel.constrainToWorkout)
            if viewModel.constrainToWorkout {
                Picker("Workout", selection: $viewModel.competition.workoutType) {
                    ForEach(WorkoutType.allCases) { workoutType in
                        Text(workoutType.rawValue.localizedCapitalized)
                            .tag(workoutType as WorkoutType?)
                    }
                }
            } else {
                Picker("Scoring model", selection: $viewModel.competition.scoringModel) {
                    ForEach(Competition.ScoringModel.allCases) { scoringModel in
                        Text(scoringModel.displayName)
                            .tag(scoringModel as Competition.ScoringModel?)
                    }
                }
            }
        } header: {
            Text("Scoring")
        } footer: {
            if viewModel.constrainToWorkout {
                Text("You can constrain a competition to a specific workout. Points can only be earned by completing the specified workout.")
            } else {
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
    }

    private var friendsView: some View {
        Section("Invite friends") {
            if viewModel.friendRows.isEmpty {
                LazyHStack {
                    Text("Nothing here, yet!")
                    Button("Add friends.", toggling: $presentAddFriends)
                }
                .padding(.vertical, 6)
            }

            ForEach(viewModel.friendRows) { rowConfig in
                HStack {
                    Text(rowConfig.name)
                    Spacer()
                    if rowConfig.invited {
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { viewModel.tapped(rowConfig) }
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
