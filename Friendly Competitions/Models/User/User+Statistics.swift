extension User {
    struct Medals: Codable, Equatable, Hashable {
        let golds: Int
        let silvers: Int
        let bronzes: Int
    }
}

extension User.Medals {
    static var zero = Self(golds: 0, silvers: 0, bronzes: 0)
}
