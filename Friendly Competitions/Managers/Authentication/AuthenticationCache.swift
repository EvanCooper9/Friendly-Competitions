import Foundation

// sourcery: AutoMockable
protocol AuthenticationCache {
    var user: User? { get set }
}

extension UserDefaults: AuthenticationCache {

    private enum Constants {
        static var userKey: String { #function }
    }

    var user: User? {
        get { decode(User.self, forKey: Constants.userKey) }
        set { encode(newValue, forKey: Constants.userKey) }
    }
}
