import Factory

extension Container {
    var storageManager: Factory<StorageManaging> {
        Factory(self) { StorageManager() }.scope(.shared)
    }
}
