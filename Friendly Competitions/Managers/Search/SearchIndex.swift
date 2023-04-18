import Combine

protocol SearchIndex {
    func search<ResultType: Decodable>(query: String) -> AnyPublisher<[ResultType], Error>
}
