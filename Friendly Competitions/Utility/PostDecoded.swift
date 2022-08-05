import Foundation

@propertyWrapper
struct PostDecoded<Strategy: PostDecodingStrategy, Value> where Strategy.Value == Value {

    var wrappedValue: Value

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

protocol PostDecodingStrategy {
    associatedtype Value: Decodable
    static func transform(_ value: Value) -> Value
}

enum DateToMidnight: PostDecodingStrategy {
    static func transform(_ value: Date) -> Date { value.advanced(by: 23.hours + 59.minutes) }
}

// MARK: - Decodable

extension PostDecoded: Decodable where Value: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = Strategy.transform(try container.decode(Value.self))
    }
}

// MARK: - Encodable

extension PostDecoded: Encodable where Value: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

// MARK: - Equatable

extension PostDecoded: Equatable where Value: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
