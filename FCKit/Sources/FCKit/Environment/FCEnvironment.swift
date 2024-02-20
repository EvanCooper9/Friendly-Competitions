public enum FCEnvironment: Codable, Equatable {
    case prod
    case debugLocal
    case debugRemote(destination: String)

    public var isDebug: Bool {
        switch self {
        case .prod:
            return false
        case .debugLocal, .debugRemote:
            return true
        }
    }

    public var bundleIdentifier: String {
        switch self {
        case .prod:
            return "com.evancooper.FriendlyCompetitions"
        case .debugLocal:
            return "com.evancooper.FriendlyCompetitions.debug"
        case .debugRemote:
            return "com.evancooper.FriendlyCompetitions.debug"
        }
    }
}
