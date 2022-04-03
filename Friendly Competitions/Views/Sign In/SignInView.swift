import SwiftUI

struct SignInView: View {

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var authenticationManager: AnyAuthenticationManager
        
    @State private var signingInWithEmail = true
    @State private var email = "test@test.com"
    @State private var password = "Password1"

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .background(content: {
                    ActivityRingView(activitySummary: nil)
                        .clipShape(Circle())
                        .if(!isPreview) { v in
                            v.shadow(radius: 10)
                        }
                })
            
            Spacer()
            Text("Friendly Competitions")
                .font(.largeTitle)
                .fontWeight(.light)
            Text("Compete against groups of friends in fitness.")
                .fontWeight(.light)
                .multilineTextAlignment(.center)
            Spacer()
            
//            if viewModel.isLoading { ProgressView() }
        
            if signingInWithEmail {
                VStack {
                    TextField(text: $email, prompt: Text("Email")) {
                        Image(systemName: "envelope.fill")
                    }
                    .textContentType(.emailAddress)
                    .disableAutocorrection(true)
                    Divider()
                    SecureField(text: $password, prompt: Text("Password")) {
                        Image(systemName: "key.fill")
                    }
                    .textContentType(.password)
                    .onSubmit {
                        authenticationManager.signIn(email: email, password: password)
                    }
                }
//                .background(.white)
                .cornerRadius(10)
                .frame(height: 60)
//                .padding(.horizontal, 20)
                .padding(.leading, 20)
            } else {
                SignInWithAppleButton()
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .onTapGesture(perform: authenticationManager.signInWithApple)
//                    .disabled(viewModel.isLoading)
                    .animation(.default, value: signingInWithEmail)
            }
            #if DEBUG
            HStack {
                if signingInWithEmail {
                    Button {
                        signingInWithEmail.toggle()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity)
                    }
                }
                HStack {
                    Image(systemName: "envelope.fill")
                    Text(signingInWithEmail ? "Sign in" : "Sign in with email")
                        .font(.title2.weight(.semibold))
                }
                .onTapGesture {
                    signingInWithEmail ? authenticationManager.signIn(email: email, password: password) : signingInWithEmail.toggle()
                }
                .frame(maxWidth: .infinity, maxHeight: 60)
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(7)
                .contentShape(Rectangle())
            }
            #endif
        }
        .padding()
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
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .withEnvironmentObjects()
    }
}
