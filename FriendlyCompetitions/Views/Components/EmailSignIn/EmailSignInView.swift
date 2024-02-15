import SwiftUI
import SwiftUIX

struct EmailSignInView: View {

    @StateObject private var viewModel: EmailSignInViewModel

    @FocusState private var focused: Bool
    @FocusState private var focusedSignInField: SignInField?
    @FocusState private var focusedSignUpField: SignUpField?

    private enum SignInField: Hashable {
        case email
        case password

        var next: Self? {
            switch self {
            case .email: return .password
            case .password: return nil
            }
        }
    }

    private enum SignUpField: Hashable {
        case name
        case email
        case password
        case passwordConfirmation

        var next: Self? {
            switch self {
            case .name: return .email
            case .email: return .password
            case .password: return .passwordConfirmation
            case .passwordConfirmation: return nil
            }
        }
    }

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
                        .textInputAutocapitalization(.never)
                        .focused($focusedSignInField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedSignInField = .password }
                    TextFieldWithSecureToggle(L10n.EmailSignIn.password, text: $viewModel.password, textContentType: .password)
                        .focused($focusedSignInField, equals: .password)
                        .submitLabel(.continue)
                        .onSubmit(viewModel.continueTapped)
                }
                .emailSignInStyle()

                Button(L10n.EmailSignIn.forgot, action: viewModel.forgotTapped)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            case .signUp:
                Group {
                    TextField(L10n.EmailSignIn.name, text: $viewModel.name)
                        .textContentType(.name)
                        .focused($focusedSignUpField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedSignUpField = .email }
                    TextField(L10n.EmailSignIn.email, text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedSignUpField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedSignUpField = .password }
                    TextFieldWithSecureToggle(L10n.EmailSignIn.password, text: $viewModel.password, textContentType: .newPassword)
                        .focused($focusedSignUpField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedSignUpField = .passwordConfirmation }
                    TextFieldWithSecureToggle(L10n.EmailSignIn.passwordConfirmation, text: $viewModel.passwordConfirmation, textContentType: .newPassword)
                        .focused($focusedSignUpField, equals: .passwordConfirmation)
                        .submitLabel(.continue)
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
                        Text(L10n.EmailSignIn.new(App.name))
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
        .padding(.horizontal)
        .withLoadingOverlay(isLoading: viewModel.loading)
        .errorAlert(error: $viewModel.error)
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
