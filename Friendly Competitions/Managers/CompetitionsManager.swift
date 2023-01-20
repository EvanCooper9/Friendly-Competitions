import Combine
import ECKit
import ECKit_Firebase
import Factory
import Firebase
import FirebaseFirestore
import FirebaseFunctionsCombineSwift
import Foundation
import UIKit

// sourcery: AutoMockable
protocol CompetitionsManaging {
    var competitions: AnyPublisher<[Competition], Never>! { get }
    var invitedCompetitions: AnyPublisher<[Competition], Never>! { get }
    var appOwnedCompetitions: AnyPublisher<[Competition], Never>! { get }
    var competitionsDateInterval: DateInterval { get }

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
    func results(for competitionID: Competition.ID) -> AnyPublisher<[CompetitionResult], Error>
    func standings(for competitionID: Competition.ID, resultID: CompetitionResult.ID) -> AnyPublisher<[Competition.Standing], Error>
    func standings(for competitionID: Competition.ID) -> AnyPublisher<[Competition.Standing], Error>
    func participants(for competitionsID: Competition.ID) -> AnyPublisher<[User], Error>
    func competitionPublisher(for competitionID: Competition.ID) -> AnyPublisher<Competition, Error>
}

final class CompetitionsManager: CompetitionsManaging {

    /// Used for searching, so we don't decode dates and other expensive properties
    private struct SearchResult: Decodable {
        let name: String
    }
    
    private enum Constants {
        static let maxParticipantsToFetch = 10
        static var competitionsDateIntervalKey: String { #function }
    }
    
    // MARK: - Public Properties

    private(set) var competitions: AnyPublisher<[Competition], Never>!
    private(set) var invitedCompetitions: AnyPublisher<[Competition], Never>!
    private(set) var appOwnedCompetitions: AnyPublisher<[Competition], Never>!
    
    private(set) var competitionsDateInterval: DateInterval

    // MARK: - Private Properties
    
    private let competitionsSubject = CurrentValueSubject<[Competition], Never>([])
    private let invitedCompetitionsSubject = CurrentValueSubject<[Competition], Never>([])
    private let appOwnedCompetitionsSubject = CurrentValueSubject<[Competition], Never>([])

    @Injected(Container.appState) private var appState
    @Injected(Container.analyticsManager) private var analyticsManager
    @Injected(Container.database) private var database
    @Injected(Container.functions) private var functions
    @Injected(Container.userManager) private var userManager
    
    private var updateTask: Task<Void, Error>? {
        willSet { updateTask?.cancel() }
    }

    private var cancellables = Cancellables()
    private var listenerBag = ListenerBag()
    
    private lazy var firestoreEncoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.dateEncodingStrategy = .formatted(.dateDashed)
        return encoder
    }()
    
    private lazy var firestoreDecoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.dateDecodingStrategy = .formatted(.dateDashed)
        return decoder
    }()

    // MARK: - Lifecycle

    init() {
        competitions = competitionsSubject.share(replay: 1).eraseToAnyPublisher()
        invitedCompetitions = invitedCompetitionsSubject.share(replay: 1).eraseToAnyPublisher()
        appOwnedCompetitions = appOwnedCompetitionsSubject.share(replay: 1).eraseToAnyPublisher()
        
        let dateInterval = UserDefaults.standard.decode(DateInterval.self, forKey: Constants.competitionsDateIntervalKey) ?? .init()
        competitionsDateInterval = dateInterval
        competitions
            .dropFirst()
            .filterMany(\.isActive)
            .map(\.dateInterval)
            .sink(withUnretained: self) { strongSelf, dateInterval in
                strongSelf.competitionsDateInterval = dateInterval
                UserDefaults.standard.encode(dateInterval, forKey: Constants.competitionsDateIntervalKey)
            }
            .store(in: &cancellables)

        appState.didBecomeActive
            .filter { $0 }
            .mapToVoid()
            .sink(withUnretained: self) { $0.listenForCompetitions() }
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
                guard let searchResult = try? document.data(as: SearchResult.self) else { return false }
                return searchResult.name
                    .components(separatedBy: " ")
                    .contains { $0.starts(with: searchText) }
                    
            }
            .compactMapMany { try? $0.decoded(as: Competition.self) }
            .eraseToAnyPublisher()
    }

    func search(byID competitionID: Competition.ID) -> AnyPublisher<Competition?, Error> {
        database.document("competitions/\(competitionID)")
            .getDocument()
            .tryMap { try $0.decoded(as: Competition.self) }
            .eraseToAnyPublisher()
    }
    
    func update(_ competition: Competition) -> AnyPublisher<Void, Error> {
        .fromAsync { [weak self] in
            try await self?.database
                .document("competitions/\(competition.id)")
                .updateDataEncodable(competition)
        }
    }
    
    func results(for competitionID: Competition.ID) -> AnyPublisher<[CompetitionResult], Error> {
        database.collection("competitions/\(competitionID)/results")
            .getDocuments()
            .map { $0.documents.decoded(asArrayOf: CompetitionResult.self) }
            .eraseToAnyPublisher()
    }
    
    func standings(for competitionID: Competition.ID, resultID: CompetitionResult.ID) -> AnyPublisher<[Competition.Standing], Error> {
        database.collection("competitions/\(competitionID)/results/\(resultID)/standings")
            .getDocuments(source: .cache)
            .catch { [weak self] error -> AnyPublisher<QuerySnapshot, any Error> in
                guard let strongSelf = self else { return .never() }
                return strongSelf.database
                    .collection("competitions/\(competitionID)/results/\(resultID)/standings")
                    .getDocuments(source: .server)
                    .eraseToAnyPublisher()
            }
            .map { $0.documents.compactMap { try? $0.data(as: Competition.Standing.self) } }
            .eraseToAnyPublisher()
    }
    
    func standings(for competitionID: Competition.ID) -> AnyPublisher<[Competition.Standing], Error> {
        functions.httpsCallable("updateCompetitionStandings")
            .call()
            .mapToVoid()
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.database.collection("competitions/\(competitionID)/standings")
                    .getDocuments()
                    .map { $0.documents.compactMap { try? $0.data(as: Competition.Standing.self) } }
                    .eraseToAnyPublisher()
            }
    }
    
    func participants(for competitionsID: Competition.ID) -> AnyPublisher<[User], Error> {
        search(byID: competitionsID)
            .map { $0?.participants ?? [] }
            .flatMapAsync { [weak self] participants in
                guard let strongSelf = self else { return [] }
                return try await strongSelf.database.collection("users")
                    .whereFieldWithChunking("id", in: participants)
                    .decoded(asArrayOf: User.self)
            }
    }
    
    func competitionPublisher(for competitionID: Competition.ID) -> AnyPublisher<Competition, Error> {
        database.document("competitions/\(competitionID)")
            .snapshotPublisher()
            .tryMap { try $0.decoded(as: Competition.self) }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

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
}

private extension Dictionary where Key == Competition.ID {
    func removeOldCompetitions(current competitions: [Competition]) -> Self {
        filter { competitionId, _ in competitions.contains(where: { $0.id == competitionId }) }
    }
}
