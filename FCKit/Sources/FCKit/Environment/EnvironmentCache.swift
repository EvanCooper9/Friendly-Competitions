import Foundation

// sourcery: AutoMockable
public protocol EnvironmentCache {
    var environment: FCEnvironment? { get set }
}

extension UserDefaults: EnvironmentCache {

    private enum Constants {
        static var environmentKey: String { #function }
    }

    public var environment: FCEnvironment? {
        get { decode(FCEnvironment.self, forKey: Constants.environmentKey) }
        set { encode(newValue, forKey: Constants.environmentKey) }
    }
}
