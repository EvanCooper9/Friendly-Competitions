import SwiftUI

extension ColorScheme {
    var textColor: Color {
        switch self {
        case .light:
            return .black
        case .dark:
            return .white
        @unknown default:
            return Color(uiColor: .lightText)
        }
    }
}
