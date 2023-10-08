import Firebase
import FirebaseAppCheck

class FCAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        DeviceCheckProvider(app: app)
    }
}
