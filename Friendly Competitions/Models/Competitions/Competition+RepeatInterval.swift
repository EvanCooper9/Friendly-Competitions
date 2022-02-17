extension Competition {
    enum RepeatInterval: Codable {
        case days(count: Int)
        case monthly

        var description: String {
            switch self {
            case .days(let count):
                return "Every \(count) day\(count > 1 ? "s" : "")"
            case .monthly:
                return "Every month"
            }
        }
    }
}
