struct Statistics: Codable {
    let golds: Int
    let silvers: Int
    let bronzes: Int
}

extension Statistics {
    static var zero = Statistics(golds: 0, silvers: 0, bronzes: 0)
}
