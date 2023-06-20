#if DEBUG
extension User {
    static var andrew: User {
        .init(
            id: "abc123",
            name: "Andrew Stapleton",
            email: "andrew@email.com"
        )
    }
    static var evan: User {
        .init(
            id: "0IQfVBJIgGdfC9CHgYefpZUQ13l1",
            name: "Evan Cooper",
            email: "evan@test.com"
        )
    }

    static var gabby: User {
        .init(
            id: "W8CwWA8GLqS5TnMNgbTZ9TO2qIG3",
            name: "Gabriella Carrier",
            email: "gabby@test.com"
        )
    }
}

extension User.Medals {
    static var mock: Self {
        .init(golds: 3, silvers: 2, bronzes: 1)
    }
}

extension Array where Element == User {
    static var mock: [User] {
        [.evan]
    }
}
#endif
