extension User {
    static var evan: User {
        .init(
            id: "abc",
            email: "evan@test.com",
            name: "Evan Cooper"
        )
    }

    static var gabby: User {
        .init(
            id: "123",
            email: "gabby@test.com",
            name: "Gabriella Carrier"
        )
    }
}

extension Array where Element == User {
    static var mock: [User] {
        [.evan]
    }
}
