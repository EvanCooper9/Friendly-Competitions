import Factory
import SwiftUI

struct SignIn: View {

    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel = SignInViewModel()

    var body: some View {
        VStack(spacing: 30) {

            VStack {
                Text(L10n.SignIn.title)
                    .font(.largeTitle)
                    .fontWeight(.light)
                Text(L10n.SignIn.subTitle)
                    .fontWeight(.light)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 30)

            if viewModel.signingInWithEmail {
                EmailSignInForm(
                    loading: viewModel.loading,
                    signingInWithEmail: $viewModel.signingInWithEmail,
                    signUp: $viewModel.isSigningUp,
                    name: $viewModel.name,
                    email: $viewModel.email,
                    password: $viewModel.password,
                    passwordConfirmation: $viewModel.passwordConfirmation,
                    onSubmit: viewModel.submit,
                    onForgot: viewModel.forgot
                )
                Spacer()
            } else {
                Asset.Images.logo.swiftUIImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .background {
                        ActivityRingView()
                            .shadow(radius: 10)
                    }

                Spacer()

                VStack {
                    Button(action: viewModel.submit) {
                        Label(L10n.SignIn.apple, systemImage: "applelogo")
                            .font(.title2.weight(.semibold))
                            .padding(8)
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(colorScheme == .light ? .white : .black)
                    .tint(colorScheme == .light ? .black : .white)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.loading)

                    Button(toggling: $viewModel.signingInWithEmail) {
                        Label(viewModel.signingInWithEmail ? L10n.VerifyEmail.signIn : L10n.SignIn.email, systemImage: .envelopeFill)
                            .font(.title2.weight(.semibold))
                            .padding(8)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.loading)
                }
            }
        }
        .padding()
        .background(color.ignoresSafeArea())
        .registerScreenView(name: "Sign In")
    }

    @ViewBuilder
    private var color: some View {
        switch colorScheme {
        case .dark:
            Color.black
        default:
            Color(red: 242/255, green: 242/255, blue: 247/255)
        }
    }
}

#if DEBUG
struct SignIn_Previews: PreviewProvider {
    static var previews: some View {
        SignIn()
            .setupMocks()
    }
}
#endif
