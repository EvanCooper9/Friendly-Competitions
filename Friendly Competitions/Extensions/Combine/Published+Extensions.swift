import Combine
import Foundation

private var cancellables: Set<AnyCancellable> = []

extension Published where Value: Codable {
    init(wrappedValue defaultValue: Value, storedWithKey key: UserDefaults.Key, store: UserDefaults = .standard) {
        let data = store.decode(Value.self, forKey: key.rawValue)
        self.init(initialValue: data ?? defaultValue)
        projectedValue
            .sink { store.encode($0, forKey: key.rawValue) }
            .store(in: &cancellables)
    }
}
