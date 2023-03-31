import Factory
import FirebaseFirestore

extension Container {
    var database: Factory<Database> {
        Factory(self) {
            let environment = self.environmentManager().environment
            let firestore = Firestore.firestore()
            let settings = firestore.settings

            switch environment {
            case .prod:
                break
            case .debugLocal:
                settings.isPersistenceEnabled = false
                settings.isSSLEnabled = false
                settings.host = "localhost:\(8080)"
            case .debugRemote(let destination):
                settings.isPersistenceEnabled = false
                settings.isSSLEnabled = false
                settings.host = "\(destination):\(8080)"
            }

            firestore.settings = settings
            return firestore
        }
        .scope(.shared)
    }
}
