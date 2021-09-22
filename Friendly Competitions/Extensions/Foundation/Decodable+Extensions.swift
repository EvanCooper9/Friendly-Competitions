import Foundation

extension Decodable {
    static func decoded(from data: Data) throws -> Self {
        try JSONDecoder.shared.decode(Self.self, from: data)
    }
}
