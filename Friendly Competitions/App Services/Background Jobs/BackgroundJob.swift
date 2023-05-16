import Combine

// sourcery: AutoMockable
protocol BackgroundJob: Decodable {
    func execute() -> AnyPublisher<Void, Never>
}
