extension User {
    struct Statistics: Codable, Equatable {
        let golds: Int
        let silvers: Int
        let bronzes: Int
    }
}

extension User.Statistics {
    static var zero = Self(golds: 0, silvers: 0, bronzes: 0)
}
