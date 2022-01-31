extension User {
    static var evan: User {
        let user = User(
            id: "NqduqRO62IfW6RkTq6otUey9xv42",
            email: "evan@test.com",
            name: "Evan Cooper"
        )
        user.statistics = .mock
        return user
    }

    static var gabby: User {
        .init(
            id: "W8CwWA8GLqS5TnMNgbTZ9TO2qIG3",
            email: "gabby@test.com",
            name: "Gabriella Carrier"
        )
    }
}

extension Statistics {
    static var mock: Statistics {
        .init(golds: 3, silvers: 2, bronzes: 1)
    }
}

extension Array where Element == User {
    static var mock: [User] {
        [.evan]
    }
}
