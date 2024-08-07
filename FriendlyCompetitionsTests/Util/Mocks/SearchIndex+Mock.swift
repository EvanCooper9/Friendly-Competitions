import Combine

@testable import FriendlyCompetitions

final class SearchIndexMock<Model: Decodable>: SearchIndex {
    var searchCallCount = 0
    var searchClosure: ((String) -> AnyPublisher<[Model], Error>)?
    func search<ResultType: Decodable>(query: String) -> AnyPublisher<[ResultType], Error> {
        searchCallCount += 1
        return searchClosure!(query)
            .map { $0 as! [ResultType] }
            .eraseToAnyPublisher()
    }

    #if DEBUG
    var uploadReturnValue: AnyPublisher<Void, Error>!
    func upload<T: Encodable>(_ models: [T]) -> AnyPublisher<Void, Error> {
        uploadReturnValue!
    }
    #endif
}
