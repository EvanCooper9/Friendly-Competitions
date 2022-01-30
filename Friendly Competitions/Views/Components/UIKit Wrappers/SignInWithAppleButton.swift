import AuthenticationServices
import SwiftUI

struct SignInWithAppleButton: UIViewRepresentable {

    @Environment(\.colorScheme) var colorScheme

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        ASAuthorizationAppleIDButton(type: .signIn, style: colorScheme == .dark ? .white : .black)
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
}
