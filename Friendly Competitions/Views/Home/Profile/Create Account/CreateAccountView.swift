import SwiftUI

struct CreateAccountView: View {

    @StateObject private var viewModel = CreateAccountViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 50) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Create account")
                    .font(.title)
                Text("Create an account so that you can receive notifications and create competitions, and more.")
                    .foregroundColor(.secondaryLabel)
                Text("Don't worry, all of your data will be migrated to your new account.")
                    .foregroundColor(.secondaryLabel)
            }

            VStack {
                SignInWithAppleButton(action: viewModel.signInWithAppleTapped)

                Button(action: viewModel.signInWithEmailTapped) {
                    Label(L10n.SignIn.email, systemImage: .envelopeFill)
                        .signInStyle()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .fittedDetents()
        .sheet(isPresented: $viewModel.showEmailSignIn, content: EmailSignInView.init)
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
