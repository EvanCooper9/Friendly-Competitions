import Foundation

extension JSONEncoder {
    static let shared: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let string = DateFormatter.full.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(string)
        }
        return encoder
    }()
}
