import Combine
import Firebase
import FirebaseFirestore
import Resolver

struct Participant: Identifiable {
    let id: String
    let name: String
}

class AnyCompetitionsManager: ObservableObject {
    @Published var competitions = [Competition]()
    @Published var standings = [Competition.ID : [Competition.Standing]]()
    @Published var participants = [Competition.ID: [Participant]]()
    @Published var pendingParticipants = [Competition.ID : [Participant]]()

    private(set) var didAccept = [Competition.ID: Bool]()
    func accept(_ competition: Competition) {
        didAccept[competition.id] = true
    }

    private(set) var didLeave = [Competition.ID: Bool]()
    func leave(_ competition: Competition) {
        didLeave[competition.id] = true
        competitions.remove(competition)
    }

    private(set) var didDelete = [Competition.ID: Bool]()
    func delete(_ competition: Competition) {
        didDelete[competition.id] = true
        competitions.remove(competition)
    }

    func create(_ competition: Competition) {
        competitions.append(competition)
    }

    private(set) var didListen = false
    func listen() {
        didListen = true
    }
}

final class CompetitionsManager: AnyCompetitionsManager {

    // MARK: - Private Properties

    @LazyInjected private var database: Firestore
    @LazyInjected private var user: User

    // MARK: - Public Methods

    override func accept(_ competition: Competition) {
        var competition = competition
        competition.pendingParticipants.remove(user.id)
        competition.participants.append(user.id)
        guard let index = competitions.firstIndex(where: { $0.id == competition.id }) else { return }
        competitions[index] = competition
        Task { [weak self, competition] in
            try await self?.database.document("competitions/\(competition.id)").updateDataEncodable(competition)
        }
    }

    override func create(_ competition: Competition) {
        competitions.append(competition)
        Task { [weak self] in
            try await self?.database.document("competitions/\(competition.id)").setDataEncodable(competition)
        }
    }

    override func leave(_ competition: Competition) {
        var competition = competition
        competition.participants.remove(user.id)
        competitions.remove(competition)
        Task { [weak self, competition] in
            try await self?.database.document("competitions/\(competition.id)").updateDataEncodable(competition)
        }
    }

    override func delete(_ competition: Competition) {
        competitions.remove(competition)
        standings[competition.id] = nil
        Task { [weak self] in
            try await self?.database.document("competitions/\(competition.id)").delete()
        }
    }

    override func listen() {
        database.collection("competitions")
            .whereField("participants", arrayContains: user.id)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print(error)
                    return
                }

                let competitions = snapshot?.documents.decoded(asArrayOf: Competition.self) ?? []
                Task { [weak self] in
                    try await self?.updateStandings(for: competitions)
                    try await self?.updateParticipants(for: competitions)
                    try await self?.updatePendingParticipants(for: competitions)
                }
                DispatchQueue.main.async { [weak self] in
                    self?.competitions = competitions
                }
            }
    }

    // MARK: - Private Methods

    private func updateStandings(for competitions: [Competition]) async throws {
        try await withThrowingTaskGroup(of: (Competition.ID, [Competition.Standing])?.self) { group in
            competitions.forEach { competition in
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let standings = try await self.database
                        .collection("competitions/\(competition.id)/standings")
                        .getDocuments()
                        .documents
                        .decoded(asArrayOf: Competition.Standing.self)
                    return (competition.id, standings)
                }
            }

            var allStandings = [Competition.ID: [Competition.Standing]]()
            for try await (competitionId, standings) in group.compactMap({ $0 }) {
                allStandings[competitionId] = standings
            }

            DispatchQueue.main.async { [weak self, allStandings] in
                self?.standings = allStandings
            }
        }
    }

    private func updateParticipants(for competitions: [Competition]) async throws {
        try await withThrowingTaskGroup(of: (Competition.ID, [Participant])?.self) { group in
            competitions.forEach { competition in
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let participants = try await self.database
                        .collection("users")
                        .whereField("id", in: competition.participants)
                        .getDocuments()
                        .documents
                        .decoded(asArrayOf: User.self)
                        .map { user in
                            Participant(
                                id: user.id,
                                name: user.name
                            )
                        }
                    return (competition.id, participants)
                }
            }

            var allParticipants = [Competition.ID: [Participant]]()
            for try await (competitionId, participants) in group.compactMap({ $0 }) {
                allParticipants[competitionId] = participants
            }

            DispatchQueue.main.async { [weak self, allParticipants] in
                self?.participants = allParticipants
            }
        }
    }

    private func updatePendingParticipants(for competitions: [Competition]) async throws {
        try await withThrowingTaskGroup(of: (Competition.ID, [Participant])?.self) { group in
            competitions.forEach { competition in
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let participants = try await self.database
                        .collection("users")
                        .whereField("id", in: competition.pendingParticipants)
                        .getDocuments()
                        .documents
                        .decoded(asArrayOf: User.self)
                        .map { user in
                            Participant(
                                id: user.id,
                                name: user.name
                            )
                        }
                    return (competition.id, participants)
                }
            }

            var allPendingParticipants = [Competition.ID: [Participant]]()
            for try await (competitionId, participants) in group.compactMap({ $0 }) {
                allPendingParticipants[competitionId] = participants
            }

            DispatchQueue.main.async { [weak self, allPendingParticipants] in
                self?.pendingParticipants = allPendingParticipants
            }
        }
    }
}
