extension Dictionary {
    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        let mapped = compactMap { key, value -> (T, Value)? in
            guard let newKey = transform(key) else { return nil }
            return (newKey, value)
        }
        return [T: Value](uniqueKeysWithValues: mapped)
    }

    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        let mapped = map { (transform($0), $1) }
        return [T: Value](uniqueKeysWithValues: mapped)
    }
}
