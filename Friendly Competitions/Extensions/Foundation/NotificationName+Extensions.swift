import Combine
import Foundation

extension Notification.Name {
    var publisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: self)
            .mapToValue(())
            .eraseToAnyPublisher()
    }
}
