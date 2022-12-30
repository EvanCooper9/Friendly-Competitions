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
    
    private let competitionsSubject = CurrentValueSubject<[Competition], Never>([])
    private let invitedCompetitionsSubject = CurrentValueSubject<[Competition], Never>([])
    private let standingsSubject = CurrentValueSubject<[Competition.ID: [Competition.Standing]], Never>([:])
    private let participantsSubject = CurrentValueSubject<[Competition.ID: [User]], Never>([:])
    private let pendingParticipantsSubject = CurrentValueSubject<[Competition.ID: [User]], Never>([:])
    private let appOwnedCompetitionsSubject = CurrentValueSubject<[Competition], Never>([])

    @Injected(Container.appState) private var appState
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
        competitions = competitionsSubject.share(replay: 1).eraseToAnyPublisher()
        invitedCompetitions = invitedCompetitionsSubject.share(replay: 1).eraseToAnyPublisher()
        standings = standingsSubject.share(replay: 1).eraseToAnyPublisher()
        participants = participantsSubject.share(replay: 1).eraseToAnyPublisher()
        pendingParticipants = pendingParticipantsSubject.share(replay: 1).eraseToAnyPublisher()
        appOwnedCompetitions = appOwnedCompetitionsSubject.share(replay: 1).eraseToAnyPublisher()

        appState.didBecomeActive
            .filter { $0 }
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
        functions.httpsCallable("respondToCompetitionInvite")
            .call([
                "competitionID": competition.id,
                "accept": true
            ])
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func create(_ competition: Competition) -> AnyPublisher<Void, Error> {
        .fromAsync { [weak self] in
            guard let self = self else { return }
            try await self.database
                .document("competitions/\(competition.id)")
                .setDataEncodable(competition)
        }
        .handleEvents(withUnretained: self, receiveOutput: {
            $0.analyticsManager.log(event: .createCompetition(name: competition.name))
        })
        .eraseToAnyPublisher()
    }

    func decline(_ competition: Competition) -> AnyPublisher<Void, Error> {
        functions.httpsCallable("respondToCompetitionInvite")
            .call([
                "competitionID": competition.id,
                "accept": false
            ])
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func delete(_ competition: Competition) -> AnyPublisher<Void, Error> {
        functions.httpsCallable("deleteCompetition")
            .call(["competitionID": competition.id])
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func invite(_ user: User, to competition: Competition) -> AnyPublisher<Void, Error> {
        functions.httpsCallable("inviteUserToCompetition")
            .call([
                "competitionID": competition.id,
                "userID": user.id
            ])
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func join(_ competition: Competition) -> AnyPublisher<Void, Error> {
        functions.httpsCallable("joinCompetition")
            .call(["competitionID": competition.id])
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func leave(_ competition: Competition) -> AnyPublisher<Void, Error> {
        functions.httpsCallable("leaveCompetition")
            .call(["competitionID": competition.id])
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func search(_ searchText: String) -> AnyPublisher<[Competition], Error> {
        database.collection("competitions")
            .whereField("isPublic", isEqualTo: true)
            .getDocuments()
            .map(\.documents)
            .filterMany { document in
                guard let searchResult = try? document.decoded(as: SearchResult.self) else { return false }
                return searchResult.name.localizedCaseInsensitiveContains(searchText)
            }
            .compactMapMany { try? $0.decoded(as: Competition.self) }
            .eraseToAnyPublisher()
    }

    func search(byID competitionID: Competition.ID) -> AnyPublisher<Competition?, Error> {
        database.document("competitions/\(competitionID)")
            .getDocument()
            .decoded(as: Competition.self)
    }
    
    func update(_ competition: Competition) -> AnyPublisher<Void, Error> {
        .fromAsync { [weak self] in
            try await self?.database
                .document("competitions/\(competition.id)")
                .updateDataEncodable(competition)
        }
    }

    // MARK: - Private Methods
    
    private func updateStandings() -> AnyPublisher<Void, Error> {
        functions.httpsCallable("updateCompetitionStandings")
            .call()
            .mapToVoid()
            .eraseToAnyPublisher()
    }
    
    private func fetchCompetitionData() {
        updateTask = Task(priority: .medium) { [weak self] in
            guard let strongSelf = self else { return }
            
            let allCompetitions = strongSelf.competitionsSubject.value +
                strongSelf.appOwnedCompetitionsSubject.value +
                strongSelf.invitedCompetitionsSubject.value
            
            try await strongSelf.fetchStandings(for: allCompetitions)
            try await strongSelf.fetchParticipants(for: allCompetitions)
            try await strongSelf.fetchPendingParticipants(for: allCompetitions)
        }
    }

    private func listenForCompetitions() {
        database.collection("competitions")
            .whereField("participants", arrayContains: userManager.user.id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                self.competitionsSubject.send(competitions)
            }
            .store(in: listenerBag)

        database.collection("competitions")
            .whereField("pendingParticipants", arrayContains: userManager.user.id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                self.invitedCompetitionsSubject.send(competitions)
            }
            .store(in: listenerBag)

        database.collection("competitions")
            .whereField("isPublic", isEqualTo: true)
            .whereField("owner", isEqualTo: Bundle.main.id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                let competitions = snapshot.documents.decoded(asArrayOf: Competition.self)
                self.appOwnedCompetitionsSubject.send(competitions)
            }
            .store(in: listenerBag)
    }

    private func fetchStandings(for competitions: [Competition]) async throws {
        guard !competitions.isEmpty else {
            standingsSubject.send([:])
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

                    if !standings.contains(where: { $0.userId == self.userManager.user.id }) {
                        let standing = try await standingsRef
                            .whereField("userId", isEqualTo: self.userManager.user.id)
                            .getDocuments()
                            .documents
                            .first?
                            .decoded(as: Competition.Standing.self)

                        if let standing { standings.append(standing) }
                    }

                    return (competition.id, standings)
                }
            }

            var newStandings = standingsSubject.value.removeOldCompetitions(current: competitions)
            for try await (competitionId, standings) in group.compactMap({ $0 }) {
                newStandings[competitionId] = standings
            }
            standingsSubject.send(newStandings)
        }
    }

    private func fetchParticipants(for competitions: [Competition]) async throws {
        guard !competitions.isEmpty else {
            participantsSubject.send([:])
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

            var newParticipants = participantsSubject.value.removeOldCompetitions(current: competitions)
            for try await (competitionId, participants) in group.compactMap({ $0 }) {
                newParticipants[competitionId] = participants
            }
            participantsSubject.send(newParticipants)
        }
    }

    private func fetchPendingParticipants(for competitions: [Competition]) async throws {
        guard !competitions.isEmpty else {
            pendingParticipantsSubject.send([:])
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
            pendingParticipantsSubject.send(pendingParticipants)
        }
    }
}

private extension Dictionary where Key == Competition.ID {
    func removeOldCompetitions(current competitions: [Competition]) -> Self {
        filter { competitionId, _ in competitions.contains(where: { $0.id == competitionId }) }
    }
}
