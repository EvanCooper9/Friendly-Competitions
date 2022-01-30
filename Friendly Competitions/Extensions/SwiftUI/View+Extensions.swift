import SwiftUI

extension View {
    func embeddedInNavigationView() -> some View {
        NavigationView {
            self
        }
    }
}
