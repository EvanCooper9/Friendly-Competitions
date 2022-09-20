@propertyWrapper
struct StringKeyEncoded<Key: Hashable & RawRepresentable, Value: Encodable>: Encodable where Key.RawValue: Encodable & Hashable {
    var wrappedValue: Dictionary<Key, Value>

    func encode(to encoder: Encoder) throws {
        let mapped = Dictionary(uniqueKeysWithValues: wrappedValue.map { ($0.key.rawValue, $0.value) })
        try mapped.encode(to: encoder)
    }
}

extension StringKeyEncoded: Decodable where Key: Decodable, Value: Decodable {}
