import Factory
import FirebaseFunctions

extension Container {
    var api: Factory<API> {
        Factory(self) {
            let environment = self.environmentManager().firestoreEnvironment
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
        .scope(.shared)
    }
}
