import Foundation

extension JSONDecoder {
    static let shared: JSONDecoder = {
        let encoder = JSONDecoder()
        encoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = DateFormatter.full.date(from: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unable to convert '\(string)' to a Date, does not match any expected formats"
                )
            }
            return date
        }
        return encoder
    }()
}
