extension User {
    static var andrew: User {
        .init(
            id: "abc123",
            email: "andrew@email.com",
            name: "Andrew Stapleton"
        )
    }
    static var evan: User {
        .init(
            id: "0IQfVBJIgGdfC9CHgYefpZUQ13l1",
            email: "evan@test.com",
            name: "Evan Cooper"
        )
    }

    static var gabby: User {
        .init(
            id: "W8CwWA8GLqS5TnMNgbTZ9TO2qIG3",
            email: "gabby@test.com",
            name: "Gabriella Carrier"
        )
    }
}

extension User.Statistics {
    static var mock: Self {
        .init(golds: 3, silvers: 2, bronzes: 1)
    }
}

extension Array where Element == User {
    static var mock: [User] {
        [.evan]
    }
}
