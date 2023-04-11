import Combine
import CombineExt
import ECKit
import Factory
import Firebase
import FirebaseFirestore
import Foundation
import UIKit

// sourcery: AutoMockable
protocol CompetitionsManaging {
    var competitions: AnyPublisher<[Competition], Never> { get }
    var invitedCompetitions: AnyPublisher<[Competition], Never> { get }
    var appOwnedCompetitions: AnyPublisher<[Competition], Never> { get }
    var competitionsDateInterval: DateInterval { get }
    var hasPremiumResults: AnyPublisher<Bool, Never> { get }

    func accept(_ competition: Competition) -> AnyPublisher<Void, Error>
    func create(_ competition: Competition) -> AnyPublisher<Void, Error>
    func decline(_ competition: Competition) -> AnyPublisher<Void, Error>
    func delete(_ competition: Competition) -> AnyPublisher<Void, Error>
    func invite(_ user: User, to competition: Competition) -> AnyPublisher<Void, Error>
    func join(_ competition: Competition) -> AnyPublisher<Void, Error>
    func leave(_ competition: Competition) -> AnyPublisher<Void, Error>
    func update(_ competition: Competition) -> AnyPublisher<Void, Error>
    func search(byID competitionID: Competition.ID) -> AnyPublisher<Competition, Error>
    func results(for competitionID: Competition.ID) -> AnyPublisher<[CompetitionResult], Error>
    func standings(for competitionID: Competition.ID, resultID: CompetitionResult.ID) -> AnyPublisher<[Competition.Standing], Error>
    func participants(for competitionsID: Competition.ID) -> AnyPublisher<[User], Error>

    func competitionPublisher(for competitionID: Competition.ID) -> AnyPublisher<Competition, Error>
    func standingsPublisher(for competitionID: Competition.ID) -> AnyPublisher<[Competition.Standing], Error>
}

final class CompetitionsManager: CompetitionsManaging {

    private enum Constants {
        static var competitionsDateIntervalKey: String { #function }
        static var hasPremiumResultsKey: String { #function }
    }

    // MARK: - Public Properties

    let competitions: AnyPublisher<[Competition], Never>
    let invitedCompetitions: AnyPublisher<[Competition], Never>
    let appOwnedCompetitions: AnyPublisher<[Competition], Never>
    var competitionsDateInterval: DateInterval { cache.competitionsDateInterval }

    private(set) lazy var hasPremiumResults: AnyPublisher<Bool, Never> = {
        competitions
            .map { competitions -> (id: String, competitions: [Competition]) in
                let id = competitions
                    .map { competition in
                        let start = DateFormatter.dateDashed.string(from: competition.start)
                        let end = DateFormatter.dateDashed.string(from: competition.end)
                        return "\(competition.id)-\(start)-\(end)"
                    }
                    .joined(separator: "_")
                return (id: id, competitions: competitions)
            }
            .removeDuplicates { $0.id == $1.id }
            .flatMapLatest(withUnretained: self) { $0.hasPremiumResults(for: $1.competitions, id: $1.id) }
            .eraseToAnyPublisher()
    }()

    // MARK: - Private Properties

    private let competitionsSubject = ReplaySubject<[Competition], Never>(bufferSize: 1)
    private let invitedCompetitionsSubject = ReplaySubject<[Competition], Never>(bufferSize: 1)
    private let appOwnedCompetitionsSubject = ReplaySubject<[Competition], Never>(bufferSize: 1)
    private let hasPremiumResultsSubject = ReplaySubject<Bool, Never>(bufferSize: 1)

    @Injected(\.api) private var api
    @Injected(\.appState) private var appState
    @Injected(\.analyticsManager) private var analyticsManager
    @Injected(\.competitionCache) private var cache
    @Injected(\.database) private var database
    @Injected(\.userManager) private var userManager
    @Injected(\.usersCache) private var usersCache

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        competitions = competitionsSubject.eraseToAnyPublisher()
        invitedCompetitions = invitedCompetitionsSubject.eraseToAnyPublisher()
        appOwnedCompetitions = appOwnedCompetitionsSubject.eraseToAnyPublisher()

        competitions
            .filterMany(\.isActive)
            .map(\.dateInterval)
            .removeDuplicates()
            .sink(withUnretained: self) { $0.cache.competitionsDateInterval = $1 }
            .store(in: &cancellables)

        appState.didBecomeActive
            .filter { $0 }
            .mapToVoid()
            .sink(withUnretained: self) { $0.listenForCompetitions() }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func accept(_ competition: Competition) -> AnyPublisher<Void, Error> {
        let data: [String: Any] = [
            "competitionID": competition.id,
            "accept": true
        ]
        return api.call("respondToCompetitionInvite", with: data)
    }

    func create(_ competition: Competition) -> AnyPublisher<Void, Error> {
        database.document("competitions/\(competition.id)")
            .set(value: competition)
            .handleEvents(withUnretained: self, receiveOutput: {
                $0.analyticsManager.log(event: .createCompetition(name: competition.name))
            })
            .eraseToAnyPublisher()
    }

    func decline(_ competition: Competition) -> AnyPublisher<Void, Error> {
        let data: [String: Any] = [
            "competitionID": competition.id,
            "accept": false
        ]
        return api.call("respondToCompetitionInvite", with: data)
    }

    func delete(_ competition: Competition) -> AnyPublisher<Void, Error> {
        let data = ["competitionID": competition.id]
        return api.call("deleteCompetition", with: data)
    }

    func invite(_ user: User, to competition: Competition) -> AnyPublisher<Void, Error> {
        let data = [
            "competitionID": competition.id,
            "userID": user.id
        ]
        return api.call("inviteUserToCompetition", with: data)
    }

    func join(_ competition: Competition) -> AnyPublisher<Void, Error> {
        let data = ["competitionID": competition.id]
        return api.call("joinCompetition", with: data)
    }

    func leave(_ competition: Competition) -> AnyPublisher<Void, Error> {
        let data = ["competitionID": competition.id]
        return api.call("leaveCompetition", with: data)
    }

    func search(byID competitionID: Competition.ID) -> AnyPublisher<Competition, Error> {
        database.document("competitions/\(competitionID)")
            .get(as: Competition.self)
            .eraseToAnyPublisher()
    }

    func update(_ competition: Competition) -> AnyPublisher<Void, Error> {
        database.document("competitions/\(competition.id)")
            .set(value: competition)
    }

    func results(for competitionID: Competition.ID) -> AnyPublisher<[CompetitionResult], Error> {
        database.collection("competitions/\(competitionID)/results")
            .whereField("participants", arrayContains: userManager.user.id)
            .getDocuments(ofType: CompetitionResult.self)
    }

    func standings(for competitionID: Competition.ID, resultID: CompetitionResult.ID) -> AnyPublisher<[Competition.Standing], Error> {
        database.collection("competitions/\(competitionID)/results/\(resultID)/standings")
            .getDocuments(ofType: Competition.Standing.self, source: .cacheFirst)
    }

    func participants(for competitionsID: Competition.ID) -> AnyPublisher<[User], Error> {
        search(byID: competitionsID)
            .map(\.participants)
            .flatMapLatest(withUnretained: self) { strongSelf, participantIDs in
                var cached = [User]()
                var participantIDsToFetch = [String]()
                participantIDs.forEach { participantID in
                    if let user = strongSelf.usersCache.users[participantID] {
                        cached.append(user)
                    } else {
                        participantIDsToFetch.append(participantID)
                    }
                }
                guard participantIDsToFetch.isNotEmpty else { return AnyPublisher<[User], Error>.just(cached) }
                return strongSelf.database.collection("users")
                    .whereField("id", asArrayOf: User.self, in: participantIDsToFetch)
                    .handleEvents(receiveOutput: { users in
                        users.forEach { strongSelf.usersCache.users[$0.id] = $0 }
                    })
                    .map { $0 + cached }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func competitionPublisher(for competitionID: Competition.ID) -> AnyPublisher<Competition, Error> {
        database.document("competitions/\(competitionID)")
            .publisher(as: Competition.self)
    }

    func standingsPublisher(for competitionID: Competition.ID) -> AnyPublisher<[Competition.Standing], Error> {
        database.collection("competitions/\(competitionID)/standings")
            .publisher(asArrayOf: Competition.Standing.self)
    }

    // MARK: - Private Methods

    private func listenForCompetitions() {
        database.collection("competitions")
            .whereField("participants", arrayContains: userManager.user.id)
            .publisher(asArrayOf: Competition.self)
            .sink(withUnretained: self) { $0.competitionsSubject.send($1) }
            .store(in: &cancellables)

        database.collection("competitions")
            .whereField("pendingParticipants", arrayContains: userManager.user.id)
            .publisher(asArrayOf: Competition.self)
            .sink(withUnretained: self) { $0.invitedCompetitionsSubject.send($1) }
            .store(in: &cancellables)

        database.collection("competitions")
            .whereField("isPublic", isEqualTo: true)
            .whereField("owner", isEqualTo: Bundle.main.id)
            .publisher(asArrayOf: Competition.self)
            .sink(withUnretained: self) { $0.appOwnedCompetitionsSubject.send($1) }
            .store(in: &cancellables)
    }

    private func hasPremiumResults(for competitions: [Competition], id: String) -> AnyPublisher<Bool, Never> {
        if let container = cache.competitionsHasPremiumResults, container.id == id, container.hasPremiumResults {
            return .just(true)
        } else {
            return competitions
                .compactMap { [weak self] competition in
                    self?.results(for: competition.id)
                        .map { $0.count > 1 }
                        .catchErrorJustReturn(false)
                }
                .combineLatest()
                .map { $0.contains(true) }
                .handleEvents(withUnretained: self, receiveOutput: { strongSelf, hasPremiumResults in
                    let container = HasPremiumResultsContainerCache(id: id, hasPremiumResults: hasPremiumResults)
                    strongSelf.cache.competitionsHasPremiumResults = container
                })
                .eraseToAnyPublisher()
        }
    }
}

private extension Dictionary where Key == Competition.ID {
    func removeOldCompetitions(current competitions: [Competition]) -> Self {
        filter { competitionId, _ in competitions.contains(where: { $0.id == competitionId }) }
    }
}

private extension Query {
    /// Attempts to get documents from the cache. If that fails, it will get documents from the server.
    /// - Returns: A publisher emitting a QuerySnapshot instance.
    func getDocumentsPreferCache() -> AnyPublisher<QuerySnapshot, Error> {
        let serverQuery = self // after query is ran, it's gone. Can't use `self` in escaping closures below
        return getDocuments(source: .cache)
            .catch { [serverQuery] _ -> AnyPublisher<QuerySnapshot, Error> in
                serverQuery.getDocuments(source: .server).eraseToAnyPublisher()
            }
            .flatMapLatest { [serverQuery] snapshot -> AnyPublisher<QuerySnapshot, Error> in
                guard snapshot.isEmpty else { return .just(snapshot) }
                return serverQuery.getDocuments(source: .server).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
