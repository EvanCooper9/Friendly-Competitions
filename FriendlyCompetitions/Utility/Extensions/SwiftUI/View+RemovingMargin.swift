import SwiftUI

extension View {
    func removingMargin() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 10, trailing: 0))
            .listRowSeparator(.hidden)
    }
}
