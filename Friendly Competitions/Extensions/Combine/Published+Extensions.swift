import Combine
import Foundation

private var cancellableSet: Set<AnyCancellable> = []

extension Published where Value: Codable {
    init(wrappedValue defaultValue: Value, storedWithKey key: String, store: UserDefaults = .standard) {
        let data = store.decode(Value.self, forKey: key)
        self.init(initialValue: data ?? defaultValue)
        projectedValue
            .sink { store.encode($0, forKey: key) }
            .store(in: &cancellableSet)
    }
}