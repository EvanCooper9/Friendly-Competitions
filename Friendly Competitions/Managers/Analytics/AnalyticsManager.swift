import Factory
import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation

// sourcery: AutoMockable
protocol AnalyticsManaging {
    func set(userId: String)
    func log(event: AnalyticsEvent)
}

final class AnalyticsManager: AnalyticsManaging {
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func set(userId: String) {
        Analytics.setUserID(userId)
        Crashlytics.crashlytics().setUserID(userId)
    }
    
    func log(event: AnalyticsEvent) {
        guard let data = try? event.encoded(using: encoder),
              let json = try? JSON.decoded(from: data, using: decoder),
              case .object(let dictionary) = json,
              let eventName = dictionary.keys.first, let parameters = dictionary[eventName],
              case .object(let nestedDictionary) = parameters
        else { return }
            
        let firebaseCompatibleDictionary = nestedDictionary.reduce(into: [String: Any]()) { partialResult, current in
            switch current.value {
            case .string(let string):
                partialResult[current.key] = string
            case .number(let number):
                partialResult[current.key] = number
            case .bool(let bool):
                partialResult[current.key] = bool
            default:
                break
            }
        }
        
        Analytics.logEvent(eventName, parameters: firebaseCompatibleDictionary)
    }
}

/// A JSON value representation. This is a bit more useful than the naïve `[String:Any]` type
/// for JSON values, since it makes sure only valid JSON values are present & supports `Equatable`
/// and `Codable`, so that you can compare values for equality and code and decode them into data
/// or strings.
fileprivate enum JSON: Decodable {
    case string(String)
    case number(Double)
    case object([String:JSON])
    case array([JSON])
    case bool(Bool)
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let object = try? container.decode([String: JSON].self) {
            self = .object(object)
        } else if let array = try? container.decode([JSON].self) {
            self = .array(array)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
            )
        }
    }
}
