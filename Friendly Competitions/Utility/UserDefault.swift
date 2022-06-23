import Foundation

@propertyWrapper
struct UserDefault<Value> {
    let key: UserDefaults.Key
    var container: UserDefaults = .standard

    var wrappedValue: Value? {
        get { container.object(forKey: key.rawValue) as? Value }
        set { container.set(newValue, forKey: key.rawValue) }
    }
}
