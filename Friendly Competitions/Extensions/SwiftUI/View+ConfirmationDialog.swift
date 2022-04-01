import SwiftUI

extension View {
    func confirmationDialog<T, V: View>(_ titleKey: LocalizedStringKey, presenting: Binding<T?>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: (T) -> V) -> some View {
        confirmationDialog(
            titleKey,
            isPresented: .init {
                presenting.wrappedValue != nil
            } set: { b in
                // do nothing
            },
            titleVisibility: titleVisibility,
            actions: {
                if let value = presenting.wrappedValue {
                    actions(value)
                }
            }
        )
    }
}
