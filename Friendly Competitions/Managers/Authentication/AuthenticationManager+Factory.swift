import Factory
import FirebaseAuth

extension Container {
    var authenticationManager: Factory<AuthenticationManaging> {
        Factory(self) { AuthenticationManager() }.scope(.shared)
    }
    
    var auth: Factory<Auth> {
        Factory(self) {
            let environment = self.environmentManager().firestoreEnvironment
            let auth = Auth.auth()
            let settings = AuthSettings()
            switch environment.type {
            case .prod:
                break
            case .debug:
                switch environment.emulationType {
                case .localhost:
                    auth.useEmulator(withHost: "localhost", port: 9099)
                case .custom:
                    auth.useEmulator(withHost: (environment.emulationDestination ?? "localhost"), port: 9099)
                }
            }

            auth.settings = settings
            return auth
        }.scope(.shared)
    }
}
