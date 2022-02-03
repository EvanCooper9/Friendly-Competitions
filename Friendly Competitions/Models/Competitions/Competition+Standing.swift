extension Competition {
    struct Standing: Codable, Equatable, Identifiable {
        var id: String { userId }
        let rank: Int
        let userId: String
        let points: Int
    }
}
