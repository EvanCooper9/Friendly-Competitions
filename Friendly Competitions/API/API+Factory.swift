import Factory
import FirebaseFunctions

extension Container {
    static let api = Factory<API>(scope: .shared) {
        let environment = Container.environmentManager().firestoreEnvironment
        let functions = Functions.functions()

        switch environment.type {
        case .prod:
            break
        case .debug:
            switch environment.emulationType {
            case .localhost:
                functions.useEmulator(withHost: "localhost", port: 5001)
            case .custom:
                functions.useEmulator(withHost: environment.emulationDestination ?? "localhost", port: 5001)
            }
        }

        return functions
    }
}
