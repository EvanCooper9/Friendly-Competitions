import Foundation

extension UserDefaults {
    func encode<T: Encodable>(_ data: T, forKey key: String) {
        set(try? JSONEncoder.shared.encode(data), forKey: key)
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder.shared.decode(T.self, from: data)
    }
}
