import Factory
import SwiftUI

struct SignIn: View {

    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel = SignInViewModel()

    var body: some View {
        VStack(spacing: 30) {
            
            VStack {
                Text("Friendly Competitions")
                    .font(.largeTitle)
                    .fontWeight(.light)
                Text("Compete against groups of friends in fitness.")
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
                Image("logo")
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
                        Label("Sign in with Apple", systemImage: "applelogo")
                            .font(.title2.weight(.semibold))
                            .padding(8)
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(colorScheme == .light ? .white : .black)
                    .tint(colorScheme == .light ? .black : .white)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.loading)

                    Button(toggling: $viewModel.signingInWithEmail) {
                        Label(viewModel.signingInWithEmail ? "Sign in" : "Sign in with Email", systemImage: "envelope.fill")
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

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        SignIn()
            .setupMocks()
    }
}
