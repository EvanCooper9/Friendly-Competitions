import Factory
import FirebaseFirestore

extension Container {

    var databaseSettings: Factory<DatabaseSettingManaging> {
        self { DatabaseSettingsManager() }.scope(.shared)
    }

    var databaseSettingsStore: Factory<DatabaseSettingsStoring> {
        self { UserDefaults.standard }.scope(.shared)
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
