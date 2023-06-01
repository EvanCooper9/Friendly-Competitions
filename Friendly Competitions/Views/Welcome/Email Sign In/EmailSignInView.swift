import SwiftUI

struct EmailSignInView: View {

    @StateObject private var viewModel = EmailSignInViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Sign in with Email")
                .font(.title)

            switch viewModel.inputType {
            case .signIn:
                Group {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    TextFieldWithSecureToggle("Password", text: $viewModel.password, textContentType: .password)
                        .onSubmit(viewModel.continueTapped)
                }
                .emailSignInStyle()

                Button("Forgot?", action: viewModel.forgotTapped)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            case .signUp:
                Group {
                    TextField("Name", text: $viewModel.name)
                        .textContentType(.name)
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    TextFieldWithSecureToggle("Password", text: $viewModel.password, textContentType: .newPassword)
                    TextFieldWithSecureToggle("Confirm Password", text: $viewModel.passwordConfirmation, textContentType: .newPassword)
                        .onSubmit(viewModel.continueTapped)
                }
                .emailSignInStyle()
            }

            Button(action: viewModel.continueTapped) {
                Text(L10n.Generics.continue)
                    .padding(.small)
                    .maxWidth(.infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.vertical)

            Divider()

            HStack {
                switch viewModel.inputType {
                case .signIn:
                    Text("New to Friendly Competitions?")
                        .foregroundColor(.secondaryLabel)
                    Button("Sign up", action: viewModel.signUpTapped)
                case .signUp:
                    Text("Have an account?")
                        .foregroundColor(.secondaryLabel)
                    Button("Sign in", action: viewModel.signInTapped)
                }
            }
            .maxWidth(.infinity)
        }
        .padding()
        .withLoadingOverlay(isLoading: viewModel.loading)
        .errorAlert(error: $viewModel.error)
        .fittedDetents()
    }
}

private extension View {
    func emailSignInStyle() -> some View {
        self.padding()
            .background(.tertiarySystemFill)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .border(RoundedRectangle(cornerRadius: 10), stroke: .init(Color.systemFill, lineWidth: 2))
    }
}

#if DEBUG
struct EmailSignInView_Previews: PreviewProvider {
    private struct Preview: View {
        @State private var isPresented = true

        var body: some View {
            Button("Show Email Sign In View", toggle: $isPresented)
                .sheet(isPresented: $isPresented, content: EmailSignInView.init)
        }
    }

    static var previews: some View {
        Preview()
            .setupMocks()
    }
}
#endif
