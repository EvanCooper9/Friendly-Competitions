import Combine
import Firebase
import FirebaseFirestore
import Resolver
import SwiftUI

class AnyCompetitionsManager: ObservableObject {

    @Published(storedWithKey: "competitions") var competitions = [Competition]()
    @Published(storedWithKey: "standings") var standings = [Competition.ID : [Competition.Standing]]()
    @Published(storedWithKey: "participants") var participants = [Competition.ID: [Participant]]()
    @Published(storedWithKey: "pendingParticipants") var pendingParticipants = [Competition.ID : [Participant]]()

    @Published var publicCompetitions = [Competition]()

    func accept(_ competition: Competition) {}
    func create(_ competition: Competition) {}
    func decline(_ competition: Competition) {}
    func delete(_ competition: Competition) {}
    func invite(_ user: User, to competition: Competition) {}
    func join(_ competition: Competition) {}
    func leave(_ competition: Competition) {}

    func updateStandings() async throws {}
}

final class CompetitionsManager: AnyCompetitionsManager {

    // MARK: - Private Properties

    @Injected private var database: Firestore
    @Injected private var userManager: AnyUserManager

    private var user: User { userManager.user }

    // MARK: - Lifecycle

    override init() {
        super.init()
        listen()
    }

    // MARK: - Public Methods

    override func accept(_ competition: Competition) {
        var competition = competition
        competition.pendingParticipants.remove(user.id)
        if !competition.participants.contains(user.id) {
            competition.participants.append(user.id)
            update(competition: competition)
        }
    }

    override func create(_ competition: Competition) {
        competitions.append(competition)
        Task { [weak self] in
            try await self?.database.document("competitions/\(competition.id)").setDataEncodable(competition)
        }
    }

    override func decline(_ competition: Competition) {
        var competition = competition
        competition.pendingParticipants.remove(user.id)
        update(competition: competition)
    }

    override func delete(_ competition: Competition) {
        competitions.remove(competition)
        standings[competition.id] = nil
        Task { [weak self] in
            guard let self = self else { return }
            let batch = self.database.batch()
            try await self.database
                .collection("competitions/\(competition.id)/standings")
                .getDocuments()
                .documents
                .map(\.documentID)
                .forEach { standingId in
                    batch.deleteDocument(self.database.document("competitions/\(competition.id)/standings/\(standingId)"))
                }
            batch.deleteDocument(self.database.document("competitions/\(competition.id)"))
            try await batch.commit()
        }
    }

    override func invite(_ user: User, to competition: Competition) {
        var competition = competition
        competition.pendingParticipants.append(user.id)
        var pendingParticipants = pendingParticipants[competition.id] ?? []
        pendingParticipants.append(.init(from: user))
        self.pendingParticipants[competition.id] = pendingParticipants
        update(competition: competition)
    }

    override func join(_ competition: Competition) {
        var competition = competition
        competition.participants.append(user.id)
        update(competition: competition)
    }

    override func leave(_ competition: Competition) {
        var competition = competition
        competition.participants.remove(user.id)
        competitions.remove(competition)
        standings[competition.id] = nil
        participants[competition.id] = nil
        pendingParticipants[competition.id] = nil
        Task { [weak self, competition] in
            try await self?.database.document("competitions/\(competition.id)/standings/\(user.id)").delete()
            try await self?.database.document("competitions/\(competition.id)").updateDataEncodable(competition)
        }
    }

    override func updateStandings() async throws {
        guard !competitions.isEmpty else { return }
        try await Functions.functions()
            .httpsCallable("updateCompetitionStandings")
            .call(["userId": self.user.id])
    }

    // MARK: - Private Methods

    private func update(competition: Competition) {
        if let index = competitions.firstIndex(where: { $0.id == competition.id }) {
            competitions[index] = competition
        } else if let index = publicCompetitions.firstIndex(where: { $0.id == competition.id }) {
            publicCompetitions[index] = competition
        }
        Task { [weak self, competition] in
            try await self?.database.document("competitions/\(competition.id)").updateDataEncodable(competition)
            try await self?.updateStandings()
        }
    }

    private func listen() {
        database.collection("competitions")
            .whereField("participants", arrayContains: user.id)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                Task { [weak self] in
                    try await self?.updateStandings(for: competitions)
                    try await self?.updateParticipants(for: competitions)
                    try await self?.updatePendingParticipants(for: competitions)
                }
                DispatchQueue.main.async { [weak self] in
                    self?.competitions = competitions
                }
            }

        database.collection("competitions")
            .whereField("public", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                DispatchQueue.main.async { [weak self] in
                    self?.publicCompetitions = competitions
                }
            }
    }

    private func updateStandings(for competitions: [Competition]) async throws {
        guard !competitions.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.standings = [:]
            }
            return
        }
        try await withThrowingTaskGroup(of: (Competition.ID, [Competition.Standing])?.self) { group in
            competitions.forEach { competition in
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let standings = try await self.database
                        .collection("competitions/\(competition.id)/standings")
                        .getDocuments()
                        .documents
                        .decoded(asArrayOf: Competition.Standing.self)
                        .sorted(by: \.rank)
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
        guard !competitions.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.participants = [:]
            }
            return
        }
        try await withThrowingTaskGroup(of: (Competition.ID, [Participant])?.self) { group in
            competitions.forEach { competition in
                guard !competition.participants.isEmpty else { return }
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let participants = try await self.database.collection("users")
                        .whereFieldWithChunking("id", in: competition.participants)
                        .decoded(asArrayOf: User.self)
                        .map(Participant.init(from:))
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
        guard !competitions.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.pendingParticipants = [:]
            }
            return
        }
        try await withThrowingTaskGroup(of: (Competition.ID, [Participant])?.self) { group in
            competitions.forEach { competition in
                guard !competition.pendingParticipants.isEmpty else { return }
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let participants = try await self.database.collection("users")
                        .whereFieldWithChunking("id", in: competition.pendingParticipants)
                        .decoded(asArrayOf: User.self)
                        .map(Participant.init(from:))
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
