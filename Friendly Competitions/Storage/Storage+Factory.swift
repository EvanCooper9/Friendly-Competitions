import Factory
import FirebaseStorage

extension Container {
    var storage: Factory<Storage> {
        Factory(self) {
            let environment = self.environmentManager().environment
            let storage = FirebaseStorage.Storage.storage()

            switch environment {
            case .prod:
                break
            case .debugLocal:
                storage.useEmulator(withHost: "localhost", port: 9000)
            case .debugRemote(let destination):
                storage.useEmulator(withHost: destination, port: 9000)
            }

            return storage.reference()
        }.scope(.shared)
    }
}
