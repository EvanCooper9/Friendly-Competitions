import Factory

extension Container {
    static let storageManager = Factory<StorageManaging>(scope: .shared, factory: StorageManager.init)
}
