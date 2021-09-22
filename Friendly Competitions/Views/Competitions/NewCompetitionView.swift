//
//  NewCompetitionView.swift
//  NewCompetitionView
//
//  Created by Evan Cooper on 2021-08-25.
//

import SwiftUI
import FirebaseFirestore
import Resolver

struct NewCompetitionView: View {

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private(set) var viewModel: NewCompetitionViewModel

    @FocusState private var nameIsFocused: Bool

    private let calendar = Calendar.current

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section("Details") {
                        TextField("Name", text: $viewModel.name, prompt: Text("Name"))
                        DatePicker("Starts",
                                   selection: $viewModel.startDate,
                                   in: PartialRangeFrom<Date>(calendar.date(from: calendar.dateComponents([.year, .month, .day], from: .nowLocal))!),
                                   displayedComponents: [.date]
                        )
                        DatePicker("Ends",
                                   selection: $viewModel.endDate,
                                   in: PartialRangeFrom<Date>(calendar.date(from: calendar.dateComponents([.year, .month, .day], from: viewModel.startDate))!),
                                   displayedComponents: [.date])
                    }

                    Section {
                        Picker("Scoring model", selection: $viewModel.scoringModel) {
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
                                        VStack(alignment: .leading) {
                                            Text(scoringModel.displayName)
                                                .font(.title3)
                                            Text(scoringModel.description)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                } footer: {
                                    Text("Scoring models will affect how scores are calculated")
                                }
                            }
                            .navigationTitle("Scoring models")
                        }
                    }

                    Section("Invite friends") {
                        List {
                            ForEach(viewModel.friends) { user in
                                HStack {
                                    Text(user.name)
                                    Spacer()
                                    if viewModel.selectedFriends.contains(user) {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { viewModel.tapped(user: user) }
                            }
                        }
                    }

                    Section {
                        Button(action: {
                            viewModel.createCompetition()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Start")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(viewModel.disabledForm)
                    }
                }
                .navigationTitle("New Competition")
            }
        }
    }

    init(friends: [User]) {
        viewModel = .init(friends: friends)
    }
}

final class NewCompetitionViewModel: ObservableObject {

    @Published var name = ""
    @Published var scoringModel = ScoringModel.percentOfGoals
    @Published var startDate = Date.now.addingTimeInterval(1.days)
    @Published var endDate = Date.now.addingTimeInterval(7.days)
    @Published var selectedFriends: Set<User>
    @Published var friends: [User]

    @LazyInjected var database: Firestore
    @LazyInjected var user: User

    var disabledForm: Bool { name.isEmpty || selectedFriends.isEmpty }

    init(friends: [User]) {
        self.friends = friends
        self.selectedFriends = .init()
    }

    func tapped(user: User) {
        if selectedFriends.contains(user) {
            selectedFriends.remove(user)
        } else {
            selectedFriends.insert(user)
        }
    }

    func createCompetition() {
        let competition = Competition(
            name: name,
            participants: selectedFriends.map(\.id).appending(user.id),
            pendingParticipants: selectedFriends.map(\.id),
            scoringModel: scoringModel,
            start: startDate,
            end: endDate
        )

        try? database.document("competitions/\(competition.id)").setDataEncodable(competition)
    }
}

struct NewCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        NewCompetitionView(friends: .mock)
    }
}
