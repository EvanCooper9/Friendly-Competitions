import Combine

// sourcery: AutoMockable
protocol API {
    func call(_ endpoint: Endpoint) -> AnyPublisher<Void, Error>
}
