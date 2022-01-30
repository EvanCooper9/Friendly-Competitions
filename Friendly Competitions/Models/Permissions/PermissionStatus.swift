import SwiftUI

enum PermissionStatus: String, Codable {
    case authorized
    case denied
    case notDetermined

    var buttonTitle: String {
        switch self {
        case .authorized:
            return "Allowed"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Allow"
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
        }
    }
}
