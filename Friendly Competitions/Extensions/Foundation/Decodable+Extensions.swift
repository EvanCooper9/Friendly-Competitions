import Foundation

extension Decodable {
    static func decoded(from data: Data, using decoder: JSONDecoder = .shared) throws -> Self {
        try decoder.decode(Self.self, from: data)
    }
}
