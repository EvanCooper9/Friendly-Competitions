import Combine
import Foundation
import SwiftUI

private var cancellables: Set<AnyCancellable> = []

extension Published where Value: Codable {
    init(wrappedValue defaultValue: Value, storedWithKey key: String, store: UserDefaults = .standard) {
        let data = store.decode(Value.self, forKey: key)
        self.init(initialValue: data ?? defaultValue)
        projectedValue
            .sink { store.encode($0, forKey: key) }
            .store(in: &cancellables)
    }
}
