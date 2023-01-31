import AlgoliaSearchClient
import Combine
import CombineExt
import ECKit
import ECKit_Firebase
import Factory

// sourcery: AutoMockable
protocol SearchManaging {
    func searchForCompetitions(byName name: String) -> AnyPublisher<[Competition], Error>
    func searchForUsers(byName name: String) -> AnyPublisher<[User], Error>
}

final class SearchManager: SearchManaging {
    
    private struct NameSearchResult: Decodable {
        let objectID: String
    }
    
    private struct NameSearchUpload: Codable {
        let objectID: String
        let name: String
    }
    
    // MARK: - Private Properties
    
    @Injected(Container.database) private var database
    
    private let searchClient: SearchClient
    private let competitionsIndex: Index
    private let userIndex: Index
    
    // MARK: - Lifecycle
    
    init() {
        searchClient = .init(appID: "WSNLKJEWQD", apiKey: "4b2d2f9f53bcd6bb53eba3e3176490e1")
        competitionsIndex = searchClient.index(withName: "competition-name")
        userIndex = searchClient.index(withName: "user-name")
    }
    
    // MARK: - Public Methods
    
    func searchForCompetitions(byName name: String) -> AnyPublisher<[Competition], Error> {
        search(index: competitionsIndex, byName: name)
            .flatMapAsync { [weak self] searchResults in
                guard let strongSelf = self else { return [] }
                return try await strongSelf.database
                    .collection("competitions")
                    .whereFieldWithChunking("id", in: searchResults)
                    .compactMap { try? $0.decoded(as: Competition.self) }
                    .filter(\.isPublic)
            }
            .first()
            .eraseToAnyPublisher()
    }
    
    func searchForUsers(byName name: String) -> AnyPublisher<[User], Error> {
        search(index: userIndex, byName: name)
            .flatMapAsync { [weak self] searchResults in
                guard let strongSelf = self else { return [] }
                return try await strongSelf.database
                    .collection("users")
                    .whereFieldWithChunking("id", in: searchResults)
                    .compactMap { try? $0.decoded(as: User.self) }
                    .filter { $0.searchable ?? false }
            }
            .first()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func search(index: Index, byName name: String) -> AnyPublisher<[String], Error> {
        let subject = PassthroughSubject<[String], Error>()
        let searchTask = index.search(query: .init(name)) { result in
            switch result {
            case .failure(let error):
                subject.send(completion: .failure(error))
            case .success(let response):
                do {
                    let searchResults: [NameSearchResult] = try response.extractHits()
                    subject.send(searchResults.map(\.objectID))
                    subject.send(completion: .finished)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        }
        return subject
            .handleEvents(
                receiveSubscription: { _ in searchTask.start() },
                receiveCancel: { searchTask.cancel() }
            )
            .eraseToAnyPublisher()
    }
}
