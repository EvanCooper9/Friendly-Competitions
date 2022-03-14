import Combine

extension Publisher where Self.Failure == Never {
    func sinkAsync(receiveValue: @escaping (Output) async throws -> Void) -> AnyCancellable {
        sink { output in
            Task {
                try await receiveValue(output)
            }
        }
    }
}
