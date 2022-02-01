import SwiftUI

extension View {
    func embeddedInNavigationView() -> some View {
        NavigationView {
            self
        }
    }

    @ViewBuilder
    func `if`<V: View>(_ condition: Bool, builder: (Self) -> V) -> some View {
        if condition {
            builder(self)
        } else {
            self
        }
    }
}
