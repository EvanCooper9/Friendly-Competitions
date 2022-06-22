import Combine

extension Publisher where Failure == Error {
    static func fromAsync(_ function: @escaping () async throws -> Output) -> AnyPublisher<Output, Failure> {
        let subject = PassthroughSubject<Output, Failure>()
        Task {
            do {
                subject.send(try await function())
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        return subject.eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Never {
    static func fromAsync(_ function: @escaping () async -> Output) -> AnyPublisher<Output, Never> {
        let subject = PassthroughSubject<Output, Failure>()
        Task {
            subject.send(await function())
        }
        return subject.eraseToAnyPublisher()
    }
}

