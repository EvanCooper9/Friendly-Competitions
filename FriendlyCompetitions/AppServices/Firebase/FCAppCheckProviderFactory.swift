import Firebase
import FirebaseAppCheck

class FCAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if RELEASE
        DeviceCheckProvider(app: app)
        #else
        nil
        #endif
    }
}
