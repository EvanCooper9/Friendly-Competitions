import Foundation

enum SignUpError: LocalizedError {
    case passwordMatch
    case profanityDetected

    var errorDescription: String? { localizedDescription }
    var localizedDescription: String {
        switch self {
        case .passwordMatch:
            return "Passwords do not match"
        case .profanityDetected:
            return "Profanity detected in your name. Please make changes, or accept the cencorship."
        }
    }
}
