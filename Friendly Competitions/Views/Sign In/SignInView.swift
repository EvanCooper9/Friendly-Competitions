import SwiftUI

struct SignInView: View {

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var authenticationManager: AnyAuthenticationManager
        
    @State private var loading = false
    @State private var error: Error?
    @State private var signingInWithEmail = false
    @State private var email = ""
    @State private var password = ""
    
    private var emailButtonDisabled: Bool {
        guard signingInWithEmail else { return false }
        return loading || email.isEmpty || password.isEmpty
    }

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .background(content: {
                    ActivityRingView()
                        .shadow(radius: 10)
                })
            
            Spacer()
            Text("Friendly Competitions")
                .font(.largeTitle)
                .fontWeight(.light)
            Text("Compete against groups of friends in fitness.")
                .fontWeight(.light)
                .multilineTextAlignment(.center)
            Spacer()
                    
            if signingInWithEmail {
                VStack {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .frame(width: 20, alignment: .center)
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                    }
                    Divider()
                        .padding(.leading)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "key.fill")
                            .frame(width: 20, alignment: .center)
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .onSubmit { signIn(with: .email(email, password: password)) }
                    }
                }
                .padding(.leading, 20)
                .frame(height: 72)
            } else {
                Button {
                    signIn(with: .apple)
                } label: {
                    Label("Sign in with Apple", systemImage: "applelogo")
                        .font(.title2.weight(.semibold))
                        .padding()
                }
                .foregroundColor(colorScheme == .light ? .white : .black)
                .tint(colorScheme == .light ? .black : .white)
                .buttonStyle(.borderedProminent)
                .disabled(loading)
                .animation(.default, value: signingInWithEmail)
            }
            #if DEBUG
            HStack {
                if signingInWithEmail {
                    Button(toggling: $signingInWithEmail) {
                        Label("Back", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(loading)
                }
                Button {
                    signingInWithEmail ?
                        signIn(with: .email(email, password: password)) :
                        signingInWithEmail.toggle()
                } label: {
                    Label(signingInWithEmail ? "Sign in" : "Sign in with Email", systemImage: "envelope.fill")
                        .font(.title2.weight(.semibold))
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(emailButtonDisabled)
                .animation(.default, value: signingInWithEmail)
            }
            #endif
        }
        .padding()
        .errorBanner(presenting: $error)
        .background(content: {
            let color: Color = {
                switch colorScheme {
                case .dark:
                    return .black
                default:
                    return Color(red: 242/255, green: 242/255, blue: 247/255)
                }
            }()
            color.ignoresSafeArea()
        })
        .registerScreenView(name: "Sign In")
    }
    
    private func signIn(with signInMethod: SignInMethod) {
        loading = true
        Task {
            var errorToShow: Error?
            do {
                try await authenticationManager.signIn(with: signInMethod)
            } catch {
                errorToShow = error
            }
            
            DispatchQueue.main.async { [errorToShow] in
                error = errorToShow
                loading = false
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .withEnvironmentObjects()
//            .preferredColorScheme(.dark)
    }
}
