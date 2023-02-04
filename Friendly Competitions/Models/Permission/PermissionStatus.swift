import SwiftUI

enum PermissionStatus: String, Codable {
    case authorized
    case denied
    case notDetermined
    case done

    var buttonTitle: String {
        switch self {
        case .authorized:
            return L10n.Permission.Status.allowed
        case .denied:
            return L10n.Permission.Status.denied
        case .notDetermined:
            return L10n.Permission.Status.allow
        case .done:
            return L10n.Permission.Status.done
        }
    }

    var buttonColor: Color {
        switch self {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .blue
        case .done:
            return .gray
        }
    }
}
