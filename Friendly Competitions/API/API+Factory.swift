import Factory
import FirebaseFunctions

extension Container {
    var api: Factory<API> {
        Factory(self) {
            let environment = self.environmentManager().environment
            let functions = Functions.functions()

            switch environment {
            case .prod:
                break
            case .debugLocal:
                functions.useEmulator(withHost: "localhost", port: 5001)
            case .debugRemote(let destination):
                functions.useEmulator(withHost: destination, port: 5001)
            }

            return functions
        }
        .scope(.shared)
    }
}
