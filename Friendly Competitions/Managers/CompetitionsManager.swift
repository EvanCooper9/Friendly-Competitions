import Combine
import ECKit
import ECKit_Firebase
import Factory
import Firebase
import FirebaseFirestore
import FirebaseFunctionsCombineSwift
import UIKit

// sourcery: AutoMockable
protocol CompetitionsManaging {
    var competitions: AnyPublisher<[Competition], Never>! { get }
    var invitedCompetitions: AnyPublisher<[Competition], Never>! { get }
    var standings: AnyPublisher<[Competition.ID : [Competition.Standing]], Never>! { get }
    var participants: AnyPublisher<[Competition.ID: [User]], Never>! { get }
    var pendingParticipants: AnyPublisher<[Competition.ID: [User]], Never>! { get }
    var appOwnedCompetitions: AnyPublisher<[Competition], Never>! { get }

    func accept(_ competition: Competition) -> AnyPublisher<Void, Error>
    func create(_ competition: Competition) -> AnyPublisher<Void, Error>
    func decline(_ competition: Competition) -> AnyPublisher<Void, Error>
    func delete(_ competition: Competition) -> AnyPublisher<Void, Error>
    func invite(_ user: User, to competition: Competition) -> AnyPublisher<Void, Error>
    func join(_ competition: Competition) -> AnyPublisher<Void, Error>
    func leave(_ competition: Competition) -> AnyPublisher<Void, Error>
    func update(_ competition: Competition) -> AnyPublisher<Void, Error>
    func search(_ searchText: String) -> AnyPublisher<[Competition], Error>
    func search(byID competitionID: Competition.ID) -> AnyPublisher<Competition?, Error>
    func updateStandings() -> AnyPublisher<Void, Error>
}

final class CompetitionsManager: CompetitionsManaging {

    /// Used for searching, so we don't decode dates and other expensive properties
    private struct SearchResult: Decodable {
        let name: String
    }
    
    private enum Constants {
        static let maxParticipantsToFetch = 10
    }
    
    // MARK: - Public Properties

    private(set) var competitions: AnyPublisher<[Competition], Never>!
    private(set) var invitedCompetitions: AnyPublisher<[Competition], Never>!
    private(set) var standings: AnyPublisher<[Competition.ID : [Competition.Standing]], Never>!
    private(set) var participants: AnyPublisher<[Competition.ID : [User]], Never>!
    private(set) var pendingParticipants: AnyPublisher<[Competition.ID : [User]], Never>!
    private(set) var appOwnedCompetitions: AnyPublisher<[Competition], Never>!

    // MARK: - Private Properties

    @Published private var _competitions = [Competition]()
    @Published private var _invitedCompetitions = [Competition]()
    @Published private var _standings = [Competition.ID : [Competition.Standing]]()
    @Published private var _participants = [Competition.ID : [User]]()
    @Published private var _pendingParticipants = [Competition.ID : [User]]()
    @Published private var _appOwnedCompetitions = [Competition]()

    @LazyInjected(Container.activitySummaryManager) private var activitySummaryManager
    @Injected(Container.analyticsManager) private var analyticsManager
    @Injected(Container.database) private var database
    @Injected(Container.functions) private var functions
    @Injected(Container.userManager) private var userManager
    @LazyInjected(Container.workoutManager) private var workoutManager

    private var updateTask: Task<Void, Error>? {
        willSet { updateTask?.cancel() }
    }

    private var cancellables = Cancellables()
    private var listenerBag = ListenerBag()

    // MARK: - Lifecycle

    init() {

        competitions = $_competitions.share(replay: 1).eraseToAnyPublisher()
        invitedCompetitions = $_invitedCompetitions.share(replay: 1).eraseToAnyPublisher()
        standings = $_standings.share(replay: 1).eraseToAnyPublisher()
        participants = $_participants.share(replay: 1).eraseToAnyPublisher()
        pendingParticipants = $_pendingParticipants.share(replay: 1).eraseToAnyPublisher()
        appOwnedCompetitions = $_appOwnedCompetitions.share(replay: 1).eraseToAnyPublisher()

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .first()
            .mapToVoid()
            .sink(withUnretained: self) { strongSelf in
                strongSelf.listen()
                strongSelf.fetchCompetitionData()
            }
            .store(in: &cancellables)

        Publishers
            .CombineLatest3(competitions, appOwnedCompetitions, invitedCompetitions)
            .map { $0 + $1 + $2 }
            .removeDuplicates()
            .mapToVoid()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
            .setFailureType(to: Error.self)
            .flatMapLatest(withUnretained: self) { $0.updateStandings() }
            .handleEvents(withUnretained: self, receiveOutput: { $0.fetchCompetitionData() })
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func accept(_ competition: Competition) -> AnyPublisher<Void, Error> {
        var competition = competition
        competition.pendingParticipants.remove(userManager.user.value.id)
        if !competition.participants.contains(userManager.user.value.id) {
            competition.participants.append(userManager.user.value.id)
        }
        _competitions.append(competition)
        _invitedCompetitions.remove(competition)
        analyticsManager.log(event: .acceptCompetition(id: competition.id))
        return update(competition)
    }

    func create(_ competition: Competition) -> AnyPublisher<Void, Error> {
        .fromAsync { [weak self] in
            guard let self = self else { return }
            try await self.database
                .document("competitions/\(competition.id)")
                .setDataEncodable(competition)
        }
        .flatMapLatest(withUnretained: self) { $0.activitySummaryManager.update() }
        .flatMapLatest(withUnretained: self) { $0.workoutManager.update() }
        .handleEvents(withUnretained: self, receiveOutput: { $0.analyticsManager.log(event: .createCompetition(name: competition.name)) })
        .eraseToAnyPublisher()
    }

    func decline(_ competition: Competition) -> AnyPublisher<Void, Error> {
        var competition = competition
        competition.pendingParticipants.remove(userManager.user.value.id)
        analyticsManager.log(event: .declineCompetition(id: competition.id))
        return update(competition)
    }

    func delete(_ competition: Competition) -> AnyPublisher<Void, Error> {
        _competitions.remove(competition)
        _standings[competition.id] = nil
        analyticsManager.log(event: .deleteCompetition(id: competition.id))
        return .fromAsync { [weak self] in
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

    func invite(_ user: User, to competition: Competition) -> AnyPublisher<Void, Error> {
        var competition = competition
        competition.pendingParticipants.append(user.id)
        analyticsManager.log(event: .inviteFriendToCompetition(id: competition.id, friendId: user.id))
        return update(competition)
    }

    func join(_ competition: Competition) -> AnyPublisher<Void, Error> {
        var competition = competition
        competition.participants.append(userManager.user.value.id)
        analyticsManager.log(event: .joinCompetition(id: competition.id))
        return update(competition)
    }

    func leave(_ competition: Competition) -> AnyPublisher<Void, Error> {
        var competition = competition
        competition.participants.remove(userManager.user.value.id)
        _competitions.remove(competition)
        _standings[competition.id] = nil
        _participants[competition.id] = nil
        _pendingParticipants[competition.id] = nil
        Task { [weak self, competition] in
            guard let self = self else { return }
            let user = userManager.user.value
            try await self.database.document("competitions/\(competition.id)/standings/\(user.id)").delete()
            try await self.database.document("competitions/\(competition.id)").updateDataEncodable(competition)
        }
        analyticsManager.log(event: .leaveCompetition(id: competition.id))
        return update(competition)
    }

    func search(_ searchText: String) -> AnyPublisher<[Competition], Error> {
        .fromAsync { [weak self] in
            guard let self = self else { return [] }
            return try await self.database
                .collection("competitions")
                .whereField("isPublic", isEqualTo: true)
                .getDocuments()
                .documents
                .filter { document in
                    guard let searchResult = try? document.decoded(as: SearchResult.self) else { return false }
                    return searchResult.name.localizedCaseInsensitiveContains(searchText)
                }
                .decoded(asArrayOf: Competition.self)
        }
    }

    func search(byID competitionID: Competition.ID) -> AnyPublisher<Competition?, Error> {
        .fromAsync { [weak self] in
            guard let self = self else { return nil }
            return try await self.database
                .document("competitions/\(competitionID)")
                .getDocument()
                .decoded(as: Competition.self)
        }
    }

    func updateStandings() -> AnyPublisher<Void, Error> {
        functions.httpsCallable("updateCompetitionStandings")
            .call()
            .mapToVoid()
            .eraseToAnyPublisher()
    }
    
    func update(_ competition: Competition) -> AnyPublisher<Void, Error> {
        if let index = _competitions.firstIndex(where: { $0.id == competition.id }) {
            _competitions[index] = competition
        } else if let index = _appOwnedCompetitions.firstIndex(where: { $0.id == competition.id }) {
            _appOwnedCompetitions[index] = competition
        }
        return .fromAsync { [weak self] in
            guard let self = self else { return }
            try await self.database.document("competitions/\(competition.id)").updateDataEncodable(competition)
        }
        .flatMapLatest(withUnretained: self) { $0.updateStandings() }
    }

    // MARK: - Private Methods
    
    private func fetchCompetitionData() {
        updateTask = Task(priority: .medium) { [weak self] in
            guard let self = self else { return }
            let allCompetitions = self._competitions + self._appOwnedCompetitions + self._invitedCompetitions
            try await self.fetchStandings(for: allCompetitions)
            try await self.fetchParticipants(for: allCompetitions)
            try await self.fetchPendingParticipants(for: allCompetitions)
        }
    }

    private func listen() {
        database.collection("competitions")
            .whereField("participants", arrayContains: userManager.user.value.id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                self._competitions = competitions
            }
            .store(in: listenerBag)

        database.collection("competitions")
            .whereField("pendingParticipants", arrayContains: userManager.user.value.id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                self._invitedCompetitions = competitions
            }
            .store(in: listenerBag)

        database.collection("competitions")
            .whereField("isPublic", isEqualTo: true)
            .whereField("owner", isEqualTo: Bundle.main.id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                self._appOwnedCompetitions = competitions
            }
            .store(in: listenerBag)
    }

    private func fetchStandings(for competitions: [Competition]) async throws {
        guard !competitions.isEmpty else {
            _standings = [:]
            return
        }
        try await withThrowingTaskGroup(of: (Competition.ID, [Competition.Standing])?.self) { group in
            competitions.forEach { competition in
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let standingsRef = self.database.collection("competitions/\(competition.id)/standings")

                    var standings = try await standingsRef
                        .order(by: "rank")
                        .limit(to: Constants.maxParticipantsToFetch)
                        .getDocuments()
                        .documents
                        .decoded(asArrayOf: Competition.Standing.self)

                    if !standings.contains(where: { $0.userId == self.userManager.user.value.id }) {
                        let standing = try await standingsRef
                            .whereField("userId", isEqualTo: self.userManager.user.value.id)
                            .getDocuments()
                            .documents
                            .first?
                            .decoded(as: Competition.Standing.self)

                        if let standing { standings.append(standing) }
                    }

                    return (competition.id, standings)
                }
            }

            var newStandings = _standings.removeOldCompetitions(current: competitions)
            for try await (competitionId, standings) in group.compactMap({ $0 }) {
                newStandings[competitionId] = standings
            }
            _standings = newStandings
        }
    }

    private func fetchParticipants(for competitions: [Competition]) async throws {
        guard !competitions.isEmpty else {
            _participants = [:]
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

            var newParticipants = _participants.removeOldCompetitions(current: competitions)
            for try await (competitionId, participants) in group.compactMap({ $0 }) {
                newParticipants[competitionId] = participants
            }
            _participants = newParticipants
        }
    }

    private func fetchPendingParticipants(for competitions: [Competition]) async throws {
        guard !competitions.isEmpty else {
            _pendingParticipants = [:]
            return
        }
        try await withThrowingTaskGroup(of: (Competition.ID, [User]).self) { group in
            competitions.forEach { competition in
                group.addTask { [weak self] in
                    guard let self = self, competition.pendingParticipants.isNotEmpty else { return (competition.id, []) }
                    let participants = try await self.database.collection("users")
                        .whereFieldWithChunking("id", in: competition.pendingParticipants)
                        .decoded(asArrayOf: User.self)
                    return (competition.id, participants)
                }
            }

            var pendingParticipants = [Competition.ID: [User]]()
            for try await (competitionId, participants) in group {
                pendingParticipants[competitionId] = participants
            }
            _pendingParticipants = pendingParticipants
        }
    }
}

private extension Dictionary where Key == Competition.ID {
    func removeOldCompetitions(current competitions: [Competition]) -> Self {
        filter { competitionId, _ in competitions.contains(where: { $0.id == competitionId }) }
    }
}
