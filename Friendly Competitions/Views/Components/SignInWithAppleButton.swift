import SwiftUI

struct SignInWithAppleButton: View {

    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Label(L10n.SignIn.apple, systemImage: "applelogo")
                .font(.title2.weight(.semibold))
                .padding(8)
                .frame(maxWidth: .infinity)
        }
        .foregroundColor(colorScheme == .light ? .white : .black)
        .tint(colorScheme == .light ? .black : .white)
        .buttonStyle(.borderedProminent)
    }
}
