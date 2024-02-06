import Foundation

// sourcery: AutoMockable
protocol AuthenticationCache {
    var currentUser: User? { get set }
}

extension UserDefaults: AuthenticationCache {

    private enum Constants {
        static var currentUserKey = "current_user"
    }

    var currentUser: User? {
        get { decode(User.self, forKey: Constants.currentUserKey) }
        set { encode(newValue, forKey: Constants.currentUserKey) }
    }
}
