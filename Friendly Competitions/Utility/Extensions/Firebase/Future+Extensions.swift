import Combine
import CombineExt
import ECKit
import FirebaseFirestore

extension Future where Output == QuerySnapshot {
    func decoded<T: Decodable>(asArrayOf type: T.Type) -> AnyPublisher<[T], Failure> {
        map { $0.documents.decoded(asArrayOf: T.self) }
            .eraseToAnyPublisher()
    }
}

extension Future where Output == DocumentSnapshot {
    func decoded<T: Decodable>(as type: T.Type) -> AnyPublisher<T?, Failure> {
        map { try? $0.decoded(as: T.self) }
            .eraseToAnyPublisher()
    }
}
