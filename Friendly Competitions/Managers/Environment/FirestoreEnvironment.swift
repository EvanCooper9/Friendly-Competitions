enum FCEnvironment: Codable, Equatable {
    case prod
    case debugLocal
    case debugRemote(destination: String)

    var isDebug: Bool {
        switch self {
        case .prod:
            return false
        case .debugLocal, .debugRemote:
            return true
        }
    }
}
