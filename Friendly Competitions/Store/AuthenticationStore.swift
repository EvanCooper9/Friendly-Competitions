import Foundation

protocol AuthenticationStoring {
    var refreshToken: String? { get set }
}

extension UserDefaults: AuthenticationStoring {
    var refreshToken: String? {
        get { decode(String.self, forKey: #function) }
        set { encode(newValue, forKey: #function) }
    }
}
