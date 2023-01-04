import Combine

extension Publisher where Failure == Error {
    func catchErrorJustReturn(_ output: Output) -> AnyPublisher<Output, Never> {
        self.catch { _ in AnyPublisher<Output, Never>.just(output) }
            .eraseToAnyPublisher()
    }
}
