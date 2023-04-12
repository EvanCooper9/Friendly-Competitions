import Foundation

enum AuthenticationError: LocalizedError {
    case missingEmail
    case passwordMatch

    var errorDescription: String? { localizedDescription }
    var localizedDescription: String {
        switch self {
        case .missingEmail:
            return L10n.AuthenticationError.missingEmail
        case .passwordMatch:
            return L10n.AuthenticationError.passwordMatch
        }
    }
}
