import AlgoliaSearchClient
import Combine
import Foundation

// sourcery: AutoMockable
protocol SearchClient {
    func index(withName name: String) -> SearchIndex
}

protocol SearchIndex {
    func search<ResultType: Decodable>(query: String) -> AnyPublisher<[ResultType], Error>

    #if DEBUG
    func upload<T: Encodable>(_ models: [T]) -> AnyPublisher<Void, Error>
    #endif
}

// MARK: - Algolia Implementation

extension AlgoliaSearchClient.SearchClient: SearchClient {
    init() {
        self.init(
            appID: "WSNLKJEWQD",
            apiKey: "4b2d2f9f53bcd6bb53eba3e3176490e1" // public API key, ok to be in source
        )
    }

    func index(withName name: String) -> SearchIndex {
        let index: Index = self.index(withName: .init(rawValue: name))
        return index
    }
}

extension AlgoliaSearchClient.Index: SearchIndex {
    func search<ResultType: Decodable>(query: String) -> AnyPublisher<[ResultType], Error> {
        Future { promise in
            search(query: .init(query)) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let response):
                    do {
                        let hits = response.hits.map(\.object)
                        let data = try JSONEncoder().encode(hits)
                        let searchResults = try JSONDecoder().decode([ResultType].self, from: data)
                        promise(.success(searchResults))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    #if DEBUG
    func upload<T: Encodable>(_ models: [T]) -> AnyPublisher<Void, Error> {
        Future { promise in
            saveObjects(models, autoGeneratingObjectID: true, requestOptions: .none) { result in
                switch result {
                case .success:
                    promise(.success(()))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    #endif
}
