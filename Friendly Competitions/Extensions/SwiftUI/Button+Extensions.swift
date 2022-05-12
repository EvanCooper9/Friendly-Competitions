import SwiftUI

extension Button where Label == Text {
    
    init<S: StringProtocol>(_ title: S, optionalAction: (() -> Void)?) {
        self = Button(title, action: {
            optionalAction?()
        })
    }
    
    init<S: StringProtocol>(_ title: S, asyncAction: @escaping () async throws -> Void) {
        self = Button(title, action: {
            Task {
                try await asyncAction()
            }
        })
    }
}

extension Button {
    init(toggling toggle: Binding<Bool>, @ViewBuilder label: () -> Label, animated: Bool = false) {
        self = Button {
            if animated {
                withAnimation {
                    toggle.wrappedValue.toggle()
                }
            } else {
                toggle.wrappedValue.toggle()
            }
        } label: {
            label()
        }
    }
    
    init(asyncAction: @escaping () async throws -> Void, @ViewBuilder label: () -> Label) {
        self = Button {
            Task {
                try await asyncAction()
            }
        } label: {
            label()
        }
    }
}

extension Button where Label == Image {
    init(systemImage: String, asyncAction: @escaping () async throws -> Void) {
        self = Button {
            try await asyncAction()
        } label: {
            Image(systemName: systemImage)
        }
    }
}

extension Button where Label == Text {
    init<S: StringProtocol>(_ title: S, toggling toggle: Binding<Bool>, animated: Bool = false) {
        self = Button(title) {
            if animated {
                withAnimation {
                    toggle.wrappedValue.toggle()
                }
            } else {
                toggle.wrappedValue.toggle()
            }
        }
    }
}

extension Button where Label == SwiftUI.Label<Text, Image> {
    init<S: StringProtocol>(_ title: S, systemImage: String, toggling toggle: Binding<Bool>, animated: Bool = false) {
        self = Button {
            if animated {
                withAnimation {
                    toggle.wrappedValue.toggle()
                }
            } else {
                toggle.wrappedValue.toggle()
            }
        } label: {
            SwiftUI.Label(title, systemImage: systemImage)
        }
    }
    
    init<S: StringProtocol>(_ title: S, systemImage: String, action: @escaping () -> Void) {
        self = Button {
            action()
        } label: {
            SwiftUI.Label(title, systemImage: systemImage)
        }
    }
    
    init<S: StringProtocol>(_ title: S, systemImage: String, asyncAction: @escaping () async throws -> Void) {
        self = Button {
            Task {
                try await asyncAction()
            }
        } label: {
            SwiftUI.Label(title, systemImage: systemImage)
        }
    }
}
