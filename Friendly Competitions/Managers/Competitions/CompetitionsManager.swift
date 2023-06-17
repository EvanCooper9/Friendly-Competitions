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
    var hasPremiumResults: AnyPublisher<Bool, Never> { get }

    func create(_ competition: Competition) -> AnyPublisher<Void, Error>
    func update(_ competition: Competition) -> AnyPublisher<Void, Error>
    func search(byID competitionID: Competition.ID) -> AnyPublisher<Competition, Error>
    func results(for competitionID: Competition.ID) -> AnyPublisher<[CompetitionResult], Error>
    func standings(for competitionID: Competition.ID, resultID: CompetitionResult.ID) -> AnyPublisher<[Competition.Standing], Error>

    func competitionPublisher(for competitionID: Competition.ID) -> AnyPublisher<Competition, Error>
    func standingsPublisher(for competitionID: Competition.ID) -> AnyPublisher<[Competition.Standing], Error>
}

final class CompetitionsManager: CompetitionsManaging {

    private enum Constants {
        static var hasPremiumResultsKey: String { #function }
    }

    // MARK: - Public Properties

    let competitions: AnyPublisher<[Competition], Never>
    let invitedCompetitions: AnyPublisher<[Competition], Never>
    let appOwnedCompetitions: AnyPublisher<[Competition], Never>

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

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        competitions = competitionsSubject.eraseToAnyPublisher()
        invitedCompetitions = invitedCompetitionsSubject.eraseToAnyPublisher()
        appOwnedCompetitions = appOwnedCompetitionsSubject.eraseToAnyPublisher()

        appState.didBecomeActive
            .filter { $0 }
            .mapToVoid()
            .sink(withUnretained: self) { $0.listenForCompetitions() }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func create(_ competition: Competition) -> AnyPublisher<Void, Error> {
        database.document("competitions/\(competition.id)")
            .set(value: competition)
            .handleEvents(withUnretained: self, receiveOutput: {
                $0.analyticsManager.log(event: .createCompetition(name: competition.name))
            })
            .eraseToAnyPublisher()
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
        let query = database.collection("competitions/\(competitionID)/results")
            .whereField("participants", arrayContains: userManager.user.id)
            .sorted(by: "end", direction: .descending)

        let cachedResults = query.getDocuments(ofType: CompetitionResult.self, source: .cache)
        let serverCount = query.count()
            .catchErrorJustReturn(0)
            .setFailureType(to: Error.self)

        return Publishers
            .CombineLatest(cachedResults, serverCount)
            .flatMapLatest { result -> AnyPublisher<[CompetitionResult], Error> in
                let (cachedResults, serverCount) = result
                let diff = serverCount - cachedResults.count
                guard diff > 0 else { return .just(cachedResults) }
                return query
                    .limit(diff)
                    .getDocuments(ofType: CompetitionResult.self, source: .server)
            }
            .eraseToAnyPublisher()
    }

    func standings(for competitionID: Competition.ID, resultID: CompetitionResult.ID) -> AnyPublisher<[Competition.Standing], Error> {
        database.collection("competitions/\(competitionID)/results/\(resultID)/standings")
            .getDocuments(ofType: Competition.Standing.self, source: .cacheFirst)
    }

    func competitionPublisher(for competitionID: Competition.ID) -> AnyPublisher<Competition, Error> {
        database.document("competitions/\(competitionID)")
            .publisher(as: Competition.self)
    }

    func standingsPublisher(for competitionID: Competition.ID) -> AnyPublisher<[Competition.Standing], Error> {
        database.collection("competitions/\(competitionID)/standings")
            .publisher(asArrayOf: Competition.Standing.self)
            .eraseToAnyPublisher()
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
