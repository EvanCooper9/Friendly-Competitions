import FirebaseAnalyticsSwift
import SwiftUI

extension View {
    /*
     analyticsScreen(
         name: "Competition",
         extraParameters: [
             "id": competition.id,
             "name": competition.name
         ]
     )
     */
    func registerScreenView(name: String, parameters: [String: Any] = [:]) -> some View {
        analyticsScreen(name: name, extraParameters: parameters)
    }
}
