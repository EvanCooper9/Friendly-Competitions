import Resolver
import SwiftUI

struct SignIn: View {

    @Environment(\.colorScheme) private var colorScheme
    @InjectedObject private var authenticationManager: AnyAuthenticationManager

    @State private var loading = false
    @State private var error: Error?
    @State private var signingInWithEmail = false

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
            
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .background {
                    ActivityRingView()
                        .shadow(radius: 10)
                }
            
            Spacer()
                    
            if signingInWithEmail {
                EmailSignInForm(
                    signingInWithEmail: $signingInWithEmail,
                    error: $error
                )
            } else {
                VStack {
                    Button {
                        signIn(with: .apple)
                    } label: {
                        Label("Sign in with Apple", systemImage: "applelogo")
                            .font(.title2.weight(.semibold))
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(colorScheme == .light ? .white : .black)
                    .tint(colorScheme == .light ? .black : .white)
                    .buttonStyle(.borderedProminent)
                    .disabled(loading)

                    Button(toggling: $signingInWithEmail) {
                        Label(signingInWithEmail ? "Sign in" : "Sign in with Email", systemImage: "envelope.fill")
                            .font(.title2.weight(.semibold))
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(loading)
                }
            }
        }
        .padding()
        .errorBanner(presenting: $error)
        .background(color.ignoresSafeArea())
        .registerScreenView(name: "Sign In")
        .onAppear {
            Task {
                try await authenticationManager.signOut()
            }
        }
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
    
    @MainActor
    private func signIn(with signInMethod: SignInMethod) {
        loading = true
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            var errorToShow: Error?
            do {
                try await authenticationManager.signIn(with: signInMethod)
            } catch {
                errorToShow = error
            }
            
            loading = false
            error = errorToShow
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        SignIn()
            .setupMocks()
//            .preferredColorScheme(.dark)
    }
}
