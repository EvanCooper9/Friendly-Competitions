import Factory
import FirebaseFirestore

public extension Container {

    var databaseSettings: Factory<DatabaseSettingManaging> {
        self { DatabaseSettingsManager() }.scope(.shared)
    }

    var databaseSettingsStore: Factory<DatabaseSettingsStoring> {
        self { UserDefaults.appGroup }.scope(.shared)
    }

    var database: Factory<Database> {
        self {
            let environment = self.environmentManager().environment
            let databaseSettings = self.databaseSettings()
            let firestore = Firestore.firestore()

            if databaseSettings.shouldResetCache {
                firestore.clearPersistence { error in
                    if let error {
                        error.reportToCrashlytics()
                    } else {
                        databaseSettings.didResetCache()
                    }
                }
            }

            let settings = firestore.settings
            settings.cacheSettings = PersistentCacheSettings()

            switch environment {
            case .prod:
                break
            case .debugLocal:
                settings.isSSLEnabled = false
                settings.host = "localhost:\(8080)"
            case .debugRemote(let destination):
                settings.isSSLEnabled = false
                settings.host = "\(destination):\(8080)"
            }
            firestore.settings = settings

            return firestore
        }
        .scope(.shared)
    }
}
