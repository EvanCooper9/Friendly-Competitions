import Combine

// sourcery: AutoMockable
protocol API {
    func call(_ endpoint: Endpoint, with data: [String: Any]?) -> AnyPublisher<Void, Error>
}

extension API {
    func call(_ endpoint: Endpoint, with data: [String: Any]? = nil) -> AnyPublisher<Void, Error> {
        call(endpoint, with: data)
    }
}
