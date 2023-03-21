import Foundation

// sourcery: AutoMockable
protocol EnvironmentCache {
    var environment: FirestoreEnvironment? { get set }
}

extension UserDefaults: EnvironmentCache {

    private enum Constants {
        static var environmentKey: String { #function }
    }

    var environment: FirestoreEnvironment? {
        get { decode(FirestoreEnvironment.self, forKey: Constants.environmentKey) }
        set { encode(newValue, forKey: Constants.environmentKey)}
    }
}
