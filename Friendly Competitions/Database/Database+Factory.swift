import Factory
import FirebaseFirestore

extension Container {
    var database: Factory<Database> {
        Factory(self) {
            let environment = self.environmentManager().firestoreEnvironment
            let firestore = Firestore.firestore()
            let settings = firestore.settings

            switch environment.type {
            case .prod:
                break
            case .debug:
                settings.isPersistenceEnabled = false
                settings.isSSLEnabled = false
                switch environment.emulationType {
                case .localhost:
                    settings.host = "localhost:\(8080)"
                case .custom:
                    settings.host = (environment.emulationDestination ?? "localhost") + ":\(8080)"
                }
            }

            firestore.settings = settings
            return firestore
        }
        .scope(.shared)
    }
}
