import Factory
import FirebaseAuth

extension Container {
    var authenticationManager: Factory<AuthenticationManaging> {
        Factory(self) { AuthenticationManager() }.scope(.shared)
    }

    var auth: Factory<Auth> {
        Factory(self) {
            let environment = self.environmentManager().environment
            let auth = Auth.auth()

            switch environment {
            case .prod:
                break
            case .debugLocal:
                auth.useEmulator(withHost: "localhost", port: 9099)
            case .debugRemote(let destination):
                auth.useEmulator(withHost: destination, port: 9099)
            }

            return auth
        }.scope(.shared)
    }
}
