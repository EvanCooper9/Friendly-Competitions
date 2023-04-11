import Foundation

// sourcery: AutoMockable
protocol EnvironmentCache {
    var environment: FCEnvironment? { get set }
}

extension UserDefaults: EnvironmentCache {

    private enum Constants {
        static var environmentKey: String { #function }
    }

    var environment: FCEnvironment? {
        get { decode(FCEnvironment.self, forKey: Constants.environmentKey) }
        set { encode(newValue, forKey: Constants.environmentKey) }
    }
}
