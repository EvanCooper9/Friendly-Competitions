import FirebaseFirestore
import Resolver
import SwiftUI

struct CompetitionView: View {

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var user: User

    @ObservedObject private var viewModel: CompetitionViewModel

    var detailListItems: [ImmutableListItem] {
        [
            .date(
                description: viewModel.competition.started ? "Started" : "Starts",
                viewModel.competition.start
            ),
            .date(
                description: viewModel.competition.ended ? "Ended" : "Ends",
                viewModel.competition.end
            ),
            .other(
                image: "plusminus.circle",
                description: "Scoring model",
                value: viewModel.competition.scoringModel.displayName
            )
        ]
    }

    var body: some View {
        VStack {
            List {
                Section("Standings") {
                    ForEach(viewModel.standings) { standing in
                        HStack {
                            Text(standing.rank.ordinalString ?? "?").bold()
                            Text(viewModel.participants.first(where: { $0.id == standing.userId })?.name ?? standing.userId)
                            Spacer()
                            Text("\(standing.points)")
                        }
                    }
                }
                
                if !viewModel.competition.pendingParticipants.isEmpty {
                    Section("Pending invites") {
                        ForEach(viewModel.pendingParticipants) {
                            Text($0.name)
                        }
                    }
                }

                Section("Details") { detailListItems.view }

                Section {
                    if viewModel.competition.pendingParticipants.contains(user.id) {
                        Button("Accept invite", action: viewModel.accept)
                    } else {
                        Button(action: {
                            viewModel.leave()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.minus")
                                Text("Leave competition")
                                    .bold()
                            }
                            .foregroundColor(.red)
                        }
                        Button(action: {
                            viewModel.delete()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete competition")
                                    .bold()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle(viewModel.competition.name)
    }

    init(competition: Competition, participants: [User] = [], standings: [Competition.Standing] = []) {
        viewModel = .init(competition: competition, participants: participants, standings: standings)
    }
}

fileprivate final class CompetitionViewModel: ObservableObject {

    @Published var competition: Competition
    @Published var participants = [User]()
    @Published var pendingParticipants = [User]()
    @Published var standings = [Competition.Standing]()

    @LazyInjected var database: Firestore
    @LazyInjected var user: User

    private var competitionDocument: DocumentReference {
        database.document("competitions/\(competition.id)")
    }

    init(competition: Competition, participants: [User] = [], standings: [Competition.Standing] = []) {
        self.competition = competition
        self.participants = participants
        self.pendingParticipants = participants.filter { competition.pendingParticipants.contains($0.id) }
        self.standings = standings

        database.collection("users")
            .whereField("id", in: competition.participants)
            .getDocuments { snapshot, _ in
                let participants = snapshot?.documents.decoded(asArrayOf: User.self) ?? []
                DispatchQueue.main.async {
                    self.participants = participants
                    self.pendingParticipants = participants.filter { competition.pendingParticipants.contains($0.id) }
                    Task {
                        try? await self.updateStandings()
                    }
                }
            }
    }

    func accept() {
        competitionDocument.updateData(["pendingParticipants": competition.pendingParticipants.removing(user.id)])
    }

    func leave() {
        competitionDocument.updateData(["participants": competition.participants.removing(user.id)])
    }

    func delete() {
        competitionDocument.delete()
    }

    private func updateStandings() async throws {
        var activitySummaries = [String: [ActivitySummary]]()
        try await withThrowingTaskGroup(of: (String, [ActivitySummary]).self) { group in
            for participantId in competition.participants.filter({ !competition.pendingParticipants.contains($0) }) {
                group.addTask {
                    let activitySummaries = try await self.database.collection("users/\(participantId)/activitySummaries")
                        .getDocuments()
                        .documents
                        .decoded(asArrayOf: ActivitySummary.self)
                        .filter { activitySummary in
                            let startCompare = Calendar.current.compare(activitySummary.date, to: self.competition.start, toGranularity: .day)
                            let endCompare = Calendar.current.compare(activitySummary.date, to: self.competition.end, toGranularity: .day)
                            let start = startCompare == .orderedDescending || startCompare == .orderedSame
                            let end = endCompare == .orderedAscending || endCompare == .orderedSame
                            return start && end
                        }

                    return (participantId, activitySummaries)
                }
            }
            for try await result in group {
                activitySummaries[result.0] = result.1
            }
        }

        let standings = activitySummaries
            .map { participantId, summaries -> (userId: String, points: Int) in
                let points = summaries.reduce(into: 0) { $0 += competition.scoringModel.score(for: $1) }
                return (participantId, points)
            }
            .sorted(by: \.points)
            .reversed()
            .enumerated()
            .map { index, result in
                Competition.Standing(
                    rank: index + 1,
                    userId: result.userId,
                    points: result.points
                )
            }

        DispatchQueue.main.async {
            self.standings = Array(standings)
        }

        let standingsReference = database.collection("competitions/\(competition.id)/standings")
        let standingsBatch = standingsReference.firestore.batch()
        try standings.forEach { standing in
            let document = standingsReference.document("\(standing.id)")
            let _ = try standingsBatch.setDataEncodable(standing, forDocument: document)
        }
        try await standingsBatch.commit()
    }
}

struct CompetitionView_Previews: PreviewProvider {

    static var competition: Competition {
        .init(
            name: "Get busy 🥵",
            participants: participants.map(\.id),
            pendingParticipants: [],// [User.gabby.id],
            scoringModel: .percentOfGoals,
            start: .now,
            end: .now.addingTimeInterval(2.days)
        )
    }

    static var participants: [User] = [.mock, .gabby]

    static var standings: [Competition.Standing] {
        participants
            .filter { !competition.pendingParticipants.contains($0.id) }
            .enumerated()
            .map { index, participant in
                .init(
                    rank: index + 1,
                    userId: participant.id,
                    points: participants.count - index
                )
            }
    }

    static var previews: some View {
        NavigationView {
            CompetitionView(competition: competition, participants: participants, standings: standings)
                .environmentObject(User.mock)
        }
    }
}
