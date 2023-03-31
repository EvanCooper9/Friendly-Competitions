enum FCEnvironment: Codable, Equatable {
    case prod
    case debugLocal
    case debugRemote(destination: String)
}
