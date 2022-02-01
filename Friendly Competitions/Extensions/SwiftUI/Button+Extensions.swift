import SwiftUI

extension Button {
    init(toggling toggle: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self = Button(action: { toggle.wrappedValue.toggle() }, label: label)
    }
}

extension Button where Label == Text {
    init<S: StringProtocol>(_ title: S, toggling toggle: Binding<Bool>) {
        self = Button(title) { toggle.wrappedValue.toggle() }
    }
}
