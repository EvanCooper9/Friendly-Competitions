import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Resolver

struct SettingsView: View {

    @EnvironmentObject var user: User
    @EnvironmentObject var database: Firestore

    @ObservedObject private var viewModel = SettingsViewModel()

    @State var presentDeleteAccountAlert = false

    var profileListItems: [ImmutableListItem] {
        [
            .name(user.name),
            .email(user.email),
        ]
    }

    var body: some View {
        NavigationView {
            List {
                Section("Profile") { profileListItems.view }

                Section("Stats") { viewModel.statsListItems.view }

                Section {
                    Button(action: { try? Auth.auth().signOut() }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.minus")
                            Text("Sign out")
                        }
                    }
                }

                Section {
                    Button(action: {
                        presentDeleteAccountAlert.toggle()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete account")
                        }
                    }
                    .foregroundColor(.red)
                } footer: {
                    Text("You will also be signed out")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
        }
        .alert("Are you sure? This cannot be undone.", isPresented: $presentDeleteAccountAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Confim", role: .destructive) {
                Task {
                    try await database.document("users/\(user.id)").delete()
                    try await Auth.auth().currentUser?.delete()
                }
            }
        }, message: {
            Text("You cannot undo this action.")
        })
        .task {
            try? await viewModel.updateCompetitions(for: user)
        }
    }
}

fileprivate final class SettingsViewModel: ObservableObject {

    @LazyInjected var database: Firestore

    @Published var statsListItems: [ImmutableListItem] = [
        .other(image: nil, description: "Total competitions", value: ""),
        .other(image: nil, description: "Active competitions", value: ""),
        .other(image: nil, description: "🥇 Golds", value: ""),
        .other(image: nil, description: "🥈 Silvers", value: ""),
        .other(image: nil, description: "🥉 Bronzes", value: "")
    ]


    func updateCompetitions(for user: User) async throws {
        var allCompetitions = [Competition]()
        var standings = [Competition.Standing]()
        try await withThrowingTaskGroup(of: Competition.Standing?.self) { group in
            let competitions = try await database.collection("competitions")
                .whereField("participants", arrayContains: user.id)
                .getDocuments()
                .documents
                .decoded(asArrayOf: Competition.self)
                .filter { !$0.pendingParticipants.contains(user.id) }

            allCompetitions = competitions

            for competition in competitions.filter(\.ended) {
                group.addTask {
                    try await self.database.collection("competitions/\(competition.id)/standings")
                        .getDocuments()
                        .documents
                        .decoded(asArrayOf: Competition.Standing.self)
                        .sorted(by: \.rank)
                        .first(where: { $0.userId == user.id })
                }
            }

            for try await result in group {
                guard let result = result else { return }
                standings.append(result)
            }
        }

        let counts = standings.reduce(into: [:]) { $0[$1.rank, default: 0] += 1 }
        let totalCompetitions = allCompetitions.count
        let activeCompetitions = allCompetitions.count - allCompetitions.filter(\.ended).count

        DispatchQueue.main.async {
            self.statsListItems = [
                .other(image: nil, description: "Total competitions", value: "\(totalCompetitions)"),
                .other(image: nil, description: "Active competitions", value: "\(activeCompetitions)"),
                .other(image: nil, description: "🥇 Golds", value: "\(counts[1] ?? 0)"),
                .other(image: nil, description: "🥈 Silvers", value: "\(counts[2] ?? 0)"),
                .other(image: nil, description: "🥉 Bronzes", value: "\(counts[3] ?? 0)")
            ]
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.Name.mode = .mock
        return SettingsView()
            .environmentObject(User.mock)
    }
}
