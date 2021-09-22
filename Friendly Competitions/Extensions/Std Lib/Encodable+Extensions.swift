import Foundation

extension Encodable {
    func jsonDictionary() throws -> [String: Any] {
        let data = try JSONEncoder.shared.encode(self)
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] ?? [:]
    }
}

extension Encodable {
    func encoded() throws -> Data {
        try JSONEncoder.shared.encode(self)
    }
}
