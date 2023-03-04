import Combine
import Foundation

// sourcery: AutoMockable
protocol Storage {
    func data(path: String) -> AnyPublisher<Data, Error>
}
