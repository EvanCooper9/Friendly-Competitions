import Combine

protocol BackgroundJob: Decodable {
    func execute() -> AnyPublisher<Void, Never>
}
