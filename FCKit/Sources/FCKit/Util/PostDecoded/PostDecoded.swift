import Foundation

@propertyWrapper
public struct PostDecoded<Strategy: PostDecodingStrategy, Value> where Strategy.Value == Value {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

public protocol PostDecodingStrategy {
    associatedtype Value: Decodable
    static func transform(_ value: Value) -> Value
}

// MARK: - Decodable

extension PostDecoded: Decodable where Value: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = Strategy.transform(try container.decode(Value.self))
    }
}

// MARK: - Encodable

extension PostDecoded: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

// MARK: - Equatable

extension PostDecoded: Equatable where Value: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

// MARK: - Hashable

extension PostDecoded: Hashable where Value: Hashable {}
