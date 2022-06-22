import Combine
import CombineExt
import Foundation

extension Publisher where Self.Failure == Never {
    func sinkAsync(receiveValue: @escaping (Output) async throws -> Void) -> AnyCancellable {
        sink { output in
            Task {
                try await receiveValue(output)
            }
        }
    }
}

extension Publisher where Failure == Never {
    func flatMapAsync<T>(asyncFunction: @escaping (Output) async throws -> T) -> AnyPublisher<T, Error> {
        self
            .setFailureType(to: Error.self)
            .flatMapAsync(asyncFunction: asyncFunction)
    }
}

extension Publisher where Failure == Error {
    func flatMapAsync<T>(asyncFunction: @escaping (Output) async throws -> T) -> AnyPublisher<T, Error> {
        self.flatMap { output -> AnyPublisher<T, Error> in
            let subject = PassthroughSubject<T, Error>()
            Task {
                do {
                    let results = try await asyncFunction(output)
                    subject.send(results)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
            return subject
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher {
    func sink() -> AnyCancellable {
        sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
}

extension Publisher {

    static func empty() -> AnyPublisher<Output, Failure> {
        Empty().eraseToAnyPublisher()
    }

    static func error(_ error: Failure) -> AnyPublisher<Output, Failure> {
        Fail(error: error).eraseToAnyPublisher()
    }

    static func just(_ output: Output, completeImmediately: Bool = true) -> AnyPublisher<Output, Failure> {
        if completeImmediately {
            return Just(output)
                .setFailureType(to: Failure.self)
                .eraseToAnyPublisher()
        } else {
            return CurrentValueSubject(output).eraseToAnyPublisher()
        }
    }

    static func never() -> AnyPublisher<Output, Failure> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
}
