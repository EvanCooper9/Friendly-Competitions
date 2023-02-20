import AlgoliaSearchClient
import Combine
import CombineExt
import ECKit
import Factory
import Foundation

// sourcery: AutoMockable
protocol SearchManaging {
    func searchForCompetitions(byName name: String) -> AnyPublisher<[Competition], Error>
    func searchForUsers(byName name: String) -> AnyPublisher<[User], Error>
}

final class SearchManager: SearchManaging {
    
    // MARK: - Private Properties
    
    @Injected(Container.userManager) private var userManager
        
    private let searchClient: SearchClient
    private let competitionsIndex: Index
    private let userIndex: Index
    
    // MARK: - Lifecycle
    
    init() {
        searchClient = .init(appID: "WSNLKJEWQD", apiKey: "4b2d2f9f53bcd6bb53eba3e3176490e1") // public API key, ok to be in source
        competitionsIndex = searchClient.index(withName: "competitions")
        userIndex = searchClient.index(withName: "users")
    }
    
    // MARK: - Public Methods
    
    func searchForCompetitions(byName name: String) -> AnyPublisher<[Competition], Error> {
        search(index: competitionsIndex, byName: name)
            .filterMany(\.isPublic)
    }
    
    func searchForUsers(byName name: String) -> AnyPublisher<[User], Error> {
        search(index: userIndex, byName: name)
            .filterMany { [weak self] user in
                guard let strongSelf = self else { return false }
                guard user.id != strongSelf.userManager.user.id else { return false }
                return user.searchable ?? false
            }
    }
    
    // MARK: - Private Methods
    
    private func search<ResultType: Decodable>(index: Index, byName name: String) -> AnyPublisher<[ResultType], Error> {
        let subject = PassthroughSubject<[ResultType], Error>()
        let searchTask = index.search(query: .init(name)) { result in
            switch result {
            case .failure(let error):
                subject.send(completion: .failure(error))
            case .success(let response):
                do {
                    let hits = response.hits.map(\.object).compactMap { $0["object"] }
                    let data = try JSONEncoder().encode(hits)
                    let searchResults = try JSONDecoder().decode([ResultType].self, from: data)
                    subject.send(searchResults)
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
