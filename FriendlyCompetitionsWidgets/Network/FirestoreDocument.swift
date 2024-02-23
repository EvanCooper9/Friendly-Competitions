import Foundation

struct FirestoreDocumentObject: Decodable {
    let document: FirestoreDocument
}

struct FirestoreDocument: Decodable {
    let fields: [String: FirestoreProperty]
}

indirect enum FirestoreProperty: Decodable {
    case string(String)
    case array([FirestoreProperty])
    case integer(Int)
    case bool(Bool)
    case map([String: FirestoreProperty])

    enum CodingKeys: String, CodingKey {
        case string = "stringValue"
        case array = "arrayValue"
        case integer = "integerValue"
        case bool = "booleanValue"
        case map = "mapValue"
    }

    var convertValueForJson: Any {
        switch self {
        case .string(let string):
            return string
        case .array(let array):
            return array.map(\.convertValueForJson)
        case .integer(let int):
            return int
        case .bool(let bool):
            return bool
        case .map(let dictionary):
            return dictionary.mapValues(\.convertValueForJson)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var allKeys = ArraySlice(container.allKeys)
        guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
            throw DecodingError.typeMismatch(FirestoreProperty.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
        }
        switch onlyKey {
        case .string:
            self = .string(try container.decode(String.self, forKey: .string))
        case .array:
            struct UnderlyingArray: Decodable {
                let values: [FirestoreProperty]?
            }
            let underlyingArray = try container.decode(UnderlyingArray.self, forKey: .array)
            self = .array(underlyingArray.values ?? [])
        case .integer:
            if let int = try? container.decode(Int.self, forKey: .integer) {
                self = .integer(int)
            } else if let stringBacked = try? container.decode(String.self, forKey: .integer), let int = Int(stringBacked) {
                self = .integer(int)
            } else {
                throw DecodingError.typeMismatch(Int.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Could not decode int from value"))
            }
        case .bool:
            self = .bool(try container.decode(Bool.self, forKey: .bool))
        case .map:
            struct UnderlyingMap: Decodable {
                let fields: [String: FirestoreProperty]?
            }
            let doc = try container.decode(UnderlyingMap.self, forKey: .map)
            self = .map(doc.fields ?? [:])
        }
    }
}
