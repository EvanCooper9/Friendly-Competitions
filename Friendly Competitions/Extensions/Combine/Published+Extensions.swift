import Combine
import Foundation

private var cancellableSet: Set<AnyCancellable> = []

extension Published where Value: Codable {
    init(wrappedValue defaultValue: Value, _ key: String, store: UserDefaults? = nil) {
        let _store: UserDefaults = store ?? .standard

        if let data = _store.data(forKey: key), let value = try? JSONDecoder.shared.decode(Value.self, from: data) {
            self.init(initialValue: value)
        } else {
            self.init(initialValue: defaultValue)
        }

        projectedValue
            .sink { newValue in
                let data = try? JSONEncoder.shared.encode(newValue)
                _store.set(data, forKey: key)
            }
            .store(in: &cancellableSet)
    }
}
