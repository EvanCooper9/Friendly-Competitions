import Foundation

struct FirestoreEnvironment: Codable {

    let type: EnvironmentType
    let emulationType: EmulationType
    let emulationDestination: String?

    static let `default` = Self.init(type: .prod, emulationType: .localhost, emulationDestination: "localhost")

    enum EnvironmentType: String, CaseIterable, Codable, Hashable, Identifiable {
        case prod
        case debug

        var id: String { rawValue }
    }

    enum EmulationType: String, CaseIterable, Codable, Hashable, Identifiable {
        case localhost
        case custom

        var id: String { rawValue }
    }
}
