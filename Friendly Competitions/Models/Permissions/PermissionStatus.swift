import SwiftUI

enum PermissionStatus: String, Codable {
    case authorized
    case denied
    case notDetermined
    case done

    var buttonTitle: String {
        switch self {
        case .authorized:
            return "Allowed"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Allow"
        case .done:
            return "Done"
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
