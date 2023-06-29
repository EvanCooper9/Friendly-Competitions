import SwiftUI

struct EmailSignInView: View {

    @StateObject private var viewModel: EmailSignInViewModel

    init(startingInputType: EmailSignInViewInputType = .signIn, canSwitchInputType: Bool = true) {
        _viewModel = .init(wrappedValue: .init(startingInputType: startingInputType, canSwitchInputType: canSwitchInputType))
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.inputType.title)
                .font(.title)

            switch viewModel.inputType {
            case .signIn:
                Group {
                    TextField(L10n.EmailSignIn.email, text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    TextFieldWithSecureToggle(L10n.EmailSignIn.password, text: $viewModel.password, textContentType: .password)
                        .onSubmit(viewModel.continueTapped)
                }
                .emailSignInStyle()

                Button(L10n.EmailSignIn.forgot, action: viewModel.forgotTapped)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            case .signUp:
                Group {
                    TextField(L10n.EmailSignIn.name, text: $viewModel.name)
                        .textContentType(.name)
                    TextField(L10n.EmailSignIn.email, text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    TextFieldWithSecureToggle(L10n.EmailSignIn.password, text: $viewModel.password, textContentType: .newPassword)
                    TextFieldWithSecureToggle(L10n.EmailSignIn.passwordConfirmation, text: $viewModel.passwordConfirmation, textContentType: .newPassword)
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

            if viewModel.canSwitchInputType {
                Divider()

                HStack {
                    switch viewModel.inputType {
                    case .signIn:
                        Text(L10n.EmailSignIn.new(Bundle.main.name))
                            .foregroundColor(.secondaryLabel)
                        Button(L10n.EmailSignIn.signUp, action: viewModel.changeInputTypeTapped)
                    case .signUp:
                        Text(L10n.EmailSignIn.haveAnAccount)
                            .foregroundColor(.secondaryLabel)
                        Button(L10n.EmailSignIn.signIn, action: viewModel.changeInputTypeTapped)
                    }
                }
                .maxWidth(.infinity)
            }
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
                .sheet(isPresented: $isPresented) {
                    EmailSignInView()
                }
        }
    }

    static var previews: some View {
        Preview()
            .setupMocks()
    }
}
#endif
