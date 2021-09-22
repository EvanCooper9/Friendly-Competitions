import FirebaseFirestore

extension DocumentSnapshot {
    func decoded<T: Decodable>(as type: T.Type) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: data() ?? [:], options: .sortedKeys)
        return try JSONDecoder.shared.decode(T.self, from: data)
    }
}

extension Array where Element: DocumentSnapshot {
    func decoded<T: Decodable>(asArrayOf type: T.Type) -> [T] {
        compactMap { try? $0.decoded(as: T.self) }
    }
}
