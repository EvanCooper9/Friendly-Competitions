import Combine
import Firebase
import FirebaseFirestore
import Resolver
import SwiftUI

class AnyCompetitionsManager: ObservableObject {

    @Published(storedWithKey: "competitions") var competitions = [Competition]()
    @Published(storedWithKey: "invitedCompetitions") var invitedCompetitions = [Competition]()
    @Published(storedWithKey: "standings") var standings = [Competition.ID : [Competition.Standing]]()
    @Published(storedWithKey: "participants") var participants = [Competition.ID: [User]]()
    @Published(storedWithKey: "pendingParticipants") var pendingParticipants = [Competition.ID: [User]]()
    @Published(storedWithKey: "appOwnedCompetitions") var appOwnedCompetitions = [Competition]()
    @Published(storedWithKey: "topCommunityCompetitions") var topCommunityCompetitions = [Competition]()

    func accept(_ competition: Competition) {}
    func createCompetition(with config: NewCompetitionEditorConfig) {}
    func decline(_ competition: Competition) {}
    func delete(_ competition: Competition) {}
    func invite(_ user: User, to competition: Competition) {}
    func join(_ competition: Competition) {}
    func leave(_ competition: Competition) {}
    func search(_ searchText: String) async throws -> [Competition] { [] }
    func updateStandings() async throws {}
}

final class CompetitionsManager: AnyCompetitionsManager {

    /// Used for searching, so we don't decode dates and other expensive properties
    private struct SearchResult: Decodable {
        let name: String
    }
    
    private enum Constants {
        static let updateStandingsFirebaseFunctionName = "updateCompetitionStandings"
    }

    // MARK: - Private Properties

    @LazyInjected private var activitySummaryManager: AnyActivitySummaryManager
    @Injected private var analyticsManager: AnyAnalyticsManager
    @Injected private var database: Firestore
    @Injected private var userManager: AnyUserManager

    private var user: User { userManager.user }

    private var updateTask: Task<Void, Error>? {
        willSet { updateTask?.cancel() }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override init() {
        super.init()
        listen()
        fetchCompetitionData()

        Publishers
            .CombineLatest3(
                competitions.publisher,
                appOwnedCompetitions.publisher,
                invitedCompetitions.publisher
            )
            .map { _ in () }
            .prepend(())
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sinkAsync { [weak self] in try await self?.updateStandings() }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    override func accept(_ competition: Competition) {
        var competition = competition
        competition.pendingParticipants.remove(user.id)
        if !competition.participants.contains(user.id) {
            competition.participants.append(user.id)
        }
        competitions.append(competition)
        invitedCompetitions.remove(competition)
        update(competition: competition)
        
        analyticsManager.log(event: .acceptCompetition(id: competition.id))
    }

    override func createCompetition(with config: NewCompetitionEditorConfig) {
        let competition = Competition(
            name: config.name,
            owner: user.id,
            participants: [user.id],
            pendingParticipants: config.invitees,
            scoringModel: config.scoringModel,
            start: config.start,
            end: config.end,
            repeats: config.repeats,
            isPublic: config.isPublic,
            banner: nil
        )
        competitions.append(competition)
        Task { [weak self, competition] in
            try await self?.database.document("competitions/\(competition.id)").setDataEncodable(competition)
            try await activitySummaryManager.update()
        }
        
        analyticsManager.log(event: .createCompetition(name: config.name))
    }

    override func decline(_ competition: Competition) {
        var competition = competition
        competition.pendingParticipants.remove(user.id)
        invitedCompetitions.remove(competition)
        standings[competition.id] = nil
        update(competition: competition)
        analyticsManager.log(event: .declineCompetition(id: competition.id))
    }

    override func delete(_ competition: Competition) {
        competitions.remove(competition)
        topCommunityCompetitions.remove(competition)
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
        analyticsManager.log(event: .deleteCompetition(id: competition.id))
    }

    override func invite(_ user: User, to competition: Competition) {
        var competition = competition
        competition.pendingParticipants.append(user.id)
        var pendingParticipants = pendingParticipants[competition.id] ?? []
        pendingParticipants.append(user)
        self.pendingParticipants[competition.id] = pendingParticipants
        update(competition: competition)
        analyticsManager.log(event: .inviteFriendToCompetition(id: competition.id, friendId: user.id))
    }

    override func join(_ competition: Competition) {
        guard !competition.participants.contains(user.id) else { return }
        var competition = competition
        competition.participants.append(user.id)
        update(competition: competition)
        analyticsManager.log(event: .joinCompetition(id: competition.id))
    }

    override func leave(_ competition: Competition) {
        var competition = competition
        competition.participants.remove(user.id)
        competitions.remove(competition)
        standings[competition.id] = nil
        participants[competition.id] = nil
        pendingParticipants[competition.id] = nil
        update(competition: competition)
        Task { [weak self, competition] in
            try await self?.database.document("competitions/\(competition.id)/standings/\(user.id)").delete()
            try await self?.database.document("competitions/\(competition.id)").updateDataEncodable(competition)
        }
        analyticsManager.log(event: .leaveCompetition(id: competition.id))
    }

    override func search(_ searchText: String) async throws -> [Competition] {
        try await self.database.collection("competitions")
            .whereField("isPublic", isEqualTo: true)
            .getDocuments()
            .documents
            .filter { document in
                guard let searchResult = try? document.decoded(as: SearchResult.self) else { return false }
                return searchResult.name.localizedCaseInsensitiveContains(searchText)
            }
            .decoded(asArrayOf: Competition.self)
    }

    override func updateStandings() async throws {
        try await Functions.functions()
            .httpsCallable(Constants.updateStandingsFirebaseFunctionName)
            .call(["userId": self.user.id])
        fetchCompetitionData()
    }

    // MARK: - Private Methods
    
    private func fetchCompetitionData() {
        updateTask = Task(priority: .medium) {
            let allCompetitions = self.competitions + self.appOwnedCompetitions + self.topCommunityCompetitions + self.invitedCompetitions
            try await self.fetchStandings(for: allCompetitions)
            try await self.fetchParticipants(for: allCompetitions)
            try await self.fetchPendingParticipants(for: allCompetitions)
        }
    }
    
    private func updateStandings(of competition: Competition) async throws {
        try await Functions.functions()
            .httpsCallable(Constants.updateStandingsFirebaseFunctionName)
            .call(["competitionId": competition.id])
        fetchCompetitionData()
    }

    private func update(competition: Competition) {
        if let index = competitions.firstIndex(where: { $0.id == competition.id }) {
            competitions[index] = competition
        } else if let index = appOwnedCompetitions.firstIndex(where: { $0.id == competition.id }) {
            appOwnedCompetitions[index] = competition
        } else if let index = topCommunityCompetitions.firstIndex(where: { $0.id == competition.id }) {
            topCommunityCompetitions[index] = competition
        }
        Task { [weak self, competition] in
            try await self?.database.document("competitions/\(competition.id)").updateDataEncodable(competition)
            try await self?.updateStandings(of: competition)
        }
    }

    private func listen() {
        database.collection("competitions")
            .whereField("participants", arrayContains: user.id)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                DispatchQueue.main.async { [weak self] in
                    self?.competitions = competitions
                }
            }

        database.collection("competitions")
            .whereField("pendingParticipants", arrayContains: user.id)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                DispatchQueue.main.async { [weak self] in
                    self?.invitedCompetitions = competitions
                }
            }

        database.collection("competitions")
            .whereField("isPublic", isEqualTo: true)
            .whereField("owner", isEqualTo: Bundle.main.id)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                DispatchQueue.main.async { [weak self] in
                    self?.appOwnedCompetitions = competitions
                }
            }

        database.collection("competitions")
            .whereField("isPublic", isEqualTo: true)
            .whereField("owner", isNotEqualTo: Bundle.main.id)
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot else { return }
                let competitions = snapshot.documents
                    .decoded(asArrayOf: Competition.self)
                    .filter { !$0.ended && !$0.participants.isEmpty }
                    .randomSample(count: 10)
                    .sorted(by: \.participants.count)
                    .reversed()
                DispatchQueue.main.async { [weak self] in
                    self?.topCommunityCompetitions = Array(competitions)
                }
            }
    }

    private func fetchStandings(for competitions: [Competition]) async throws {
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
                    let standingsRef = self.database.collection("competitions/\(competition.id)/standings")

                    var standings = try await standingsRef
                        .order(by: "rank")
                        .limit(to: 10)
                        .getDocuments()
                        .documents
                        .decoded(asArrayOf: Competition.Standing.self)

                    if !standings.contains(where: { $0.userId == self.userManager.user.id }) {
                        let standing = try await standingsRef
                            .whereField("userId", isEqualTo: self.userManager.user.id)
                            .getDocuments()
                            .documents
                            .first?
                            .decoded(as: Competition.Standing.self)

                        if let standing = standing { standings.append(standing) }
                    }

                    return (competition.id, standings)
                }
            }

            var newStandings = self.standings.removeOldCompetitions(current: self.competitions)
            for try await (competitionId, standings) in group.compactMap({ $0 }) {
                newStandings[competitionId] = standings
            }

            try Task.checkCancellation()
            DispatchQueue.main.async { [weak self, newStandings] in
                self?.standings = newStandings
            }
        }
    }

    private func fetchParticipants(for competitions: [Competition]) async throws {
        guard !competitions.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.participants = [:]
            }
            return
        }
        try await withThrowingTaskGroup(of: (Competition.ID, [User])?.self) { group in
            competitions.forEach { competition in
                guard !competition.participants.isEmpty else { return }
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let participants = try await self.database.collection("users")
                        .whereFieldWithChunking("id", in: competition.participants)
                        .decoded(asArrayOf: User.self)
                    return (competition.id, participants)
                }
            }

            var newParticipants = self.participants.removeOldCompetitions(current: self.competitions)
            for try await (competitionId, participants) in group.compactMap({ $0 }) {
                newParticipants[competitionId] = participants
            }

            try Task.checkCancellation()
            DispatchQueue.main.async { [weak self, newParticipants] in
                self?.participants = newParticipants
            }
        }
    }

    private func fetchPendingParticipants(for competitions: [Competition]) async throws {
        guard !competitions.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.pendingParticipants = [:]
            }
            return
        }
        try await withThrowingTaskGroup(of: (Competition.ID, [User])?.self) { group in
            competitions.forEach { competition in
                guard !competition.pendingParticipants.isEmpty else { return }
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let participants = try await self.database.collection("users")
                        .whereFieldWithChunking("id", in: competition.pendingParticipants)
                        .decoded(asArrayOf: User.self)
                    return (competition.id, participants)
                }
            }

            var newPendingParticipants = self.pendingParticipants.removeOldCompetitions(current: self.competitions)
            for try await (competitionId, participants) in group.compactMap({ $0 }) {
                newPendingParticipants[competitionId] = participants
            }

            try Task.checkCancellation()
            DispatchQueue.main.async { [weak self, newPendingParticipants] in
                self?.pendingParticipants = newPendingParticipants
            }
        }
    }
}

private extension Dictionary where Key == Competition.ID {
    func removeOldCompetitions(current competitions: [Competition]) -> Self {
        filter { competitionId, _ in competitions.contains(where: { $0.id == competitionId }) }
    }
}
