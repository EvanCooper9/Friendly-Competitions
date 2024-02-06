import SwiftUI

struct SignInWithAppleButton: View {

    let title: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(_ title: String = L10n.SignIn.apple, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "applelogo")
                .font(.title2.weight(.semibold))
                .padding(8)
                .frame(maxWidth: .infinity)
        }
        .foregroundColor(colorScheme == .light ? .white : .black)
        .tint(colorScheme == .light ? .black : .white)
        .buttonStyle(.borderedProminent)
    }
}
