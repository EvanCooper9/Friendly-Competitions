import Foundation

enum SignUpError: LocalizedError {
    case passwordMatch

    var errorDescription: String? { localizedDescription }
    var localizedDescription: String {
        switch self {
        case .passwordMatch:
            return "Passwords do not match"
        }
    }
}
