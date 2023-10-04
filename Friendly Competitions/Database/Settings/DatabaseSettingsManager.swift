import Factory
import Foundation

// sourcery: AutoMockable
protocol DatabaseSettingManaging {
    var shouldResetCache: Bool { get }
    func didResetCache()
}

final class DatabaseSettingsManager: DatabaseSettingManaging {

    // MARK: - Private Properties

    @Injected(\.databaseSettingsStore) private var databaseSettingsStore
    @Injected(\.featureFlagManager) private var featureFlagManager

    // MARK: - Public Properties

    var shouldResetCache: Bool {
        let ttl = featureFlagManager.value(forDouble: .databaseCacheTtl)
        return databaseSettingsStore.lastCacheReset.addingTimeInterval(ttl) <= .now
    }

    // MARK: - Public Methods

    func didResetCache() {
        databaseSettingsStore.lastCacheReset = .now
    }
}
