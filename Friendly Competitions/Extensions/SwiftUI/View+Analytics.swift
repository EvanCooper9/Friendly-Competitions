import FirebaseAnalyticsSwift
import SwiftUI

extension View {
    func registerScreenView(name: String, parameters: [String: Any] = [:]) -> some View {
        analyticsScreen(name: name, extraParameters: parameters)
    }
}
