import SwiftUI

struct CreateAccountView: View {

    @StateObject private var viewModel = CreateAccountViewModel()

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 50) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.CreateAccount.title)
                    .font(.title)
                Text(L10n.CreateAccount.desctiption)
                    .foregroundColor(.secondaryLabel)
            }

            VStack {
                SignInWithAppleButton(L10n.CreateAccount.apple, action: viewModel.signInWithAppleTapped)

                Button(action: viewModel.signInWithEmailTapped) {
                    Label(L10n.CreateAccount.email, systemImage: .envelopeFill)
                        .signInStyle()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .fittedDetents(defaultDetents: [.large])
        .sheet(isPresented: $viewModel.showEmailSignIn) {
            EmailSignInView(startingInputType: .signUp, canSwitchInputType: false)
        }
        .onChange(of: viewModel.dismiss) { _ in dismiss() }
        .errorAlert(error: $viewModel.error)
    }
}

#if DEBUG
struct CreateAccountView_Previews: PreviewProvider {

    private struct Preview: View {
        @State private var isPresented = true

        var body: some View {
            Button("Show Create Account View", toggle: $isPresented)
                .sheet(isPresented: $isPresented, content: CreateAccountView.init)
        }
    }

    static var previews: some View {
        Preview()
            .setupMocks()
    }
}
#endif
