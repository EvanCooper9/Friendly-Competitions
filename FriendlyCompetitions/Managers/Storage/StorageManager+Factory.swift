import Factory

extension Container {
    var storageManager: Factory<StorageManaging> {
        self { StorageManager() }.scope(.shared)
    }
}
