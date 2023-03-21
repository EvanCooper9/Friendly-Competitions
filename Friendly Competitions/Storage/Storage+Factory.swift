import Factory
import FirebaseStorage

extension Container {
    var storage: Factory<Storage> {
        Factory(self) {
            let environment = self.environmentManager().firestoreEnvironment
            let storage = FirebaseStorage.Storage.storage()

            switch environment.type {
            case .prod:
                break
            case .debug:
                switch environment.emulationType {
                case .localhost:
                    storage.useEmulator(withHost: "localhost", port: 9000)
                case .custom:
                    storage.useEmulator(withHost: environment.emulationDestination ?? "localhost", port: 9000)
                }
            }

            return storage.reference()
        }.scope(.shared)
    }
}
