import Resolver
import SwiftUI

struct SignIn: View {

    @Environment(\.colorScheme) private var colorScheme
    @InjectedObject private var appState: AppState
    @InjectedObject private var authenticationManager: AnyAuthenticationManager

    @State private var loading = false
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
                EmailSignInForm(signingInWithEmail: $signingInWithEmail)
            } else {
                VStack {
                    Button {
                        loading = true
                        do {
                            try await authenticationManager.signIn(with: .apple)
                        } catch {
                            appState.hudState = .error(error)
                        }
                        loading = false
                    } label: {
                        Label("Sign in with Apple", systemImage: "applelogo")
                            .font(.title2.weight(.semibold))
                            .padding(8)
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(colorScheme == .light ? .white : .black)
                    .tint(colorScheme == .light ? .black : .white)
                    .buttonStyle(.borderedProminent)
                    .disabled(loading)

                    Button(toggling: $signingInWithEmail) {
                        Label(signingInWithEmail ? "Sign in" : "Sign in with Email", systemImage: "envelope.fill")
                            .font(.title2.weight(.semibold))
                            .padding(8)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(loading)
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
