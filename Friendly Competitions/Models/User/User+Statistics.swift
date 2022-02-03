extension User {
    struct Statistics: Codable {

        static var zero = Statistics(golds: 0, silvers: 0, bronzes: 0)

        let golds: Int
        let silvers: Int
        let bronzes: Int
    }
}
