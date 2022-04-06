import Resolver
import SwiftUI

struct EmailSignInForm: View {
    
    private enum Field: Hashable {
        case name
        case email
        case password
        case passwordConfirmation
    }
    
    @Binding var signingInWithEmail: Bool
    
    @InjectedObject private var appState: AppState
    @InjectedObject private var authenticationManager: AnyAuthenticationManager
    
    @FocusState private var focus: Field?
    
    @State private var loading = false
    @State private var signUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    
    private var submitDisabled: Bool {
        let signInConditions = email.isEmpty || password.isEmpty
        let signUpConditions = signInConditions || name.isEmpty || passwordConfirmation.isEmpty
        return loading || (signUp ? signUpConditions : signInConditions)
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Text("\(signUp ? "Have" : "Need") an account?")
                    .foregroundColor(.gray)
                Button(signUp ? "Sign in" : "Sign up", toggling: $signUp)
            }
            .font(.callout)
            .disabled(loading)
            
            VStack(spacing: 5) {
                if signUp {
                    HStack {
                        Image(systemName: "person.fill")
                            .frame(width: 20, alignment: .center)
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .focused($focus, equals: .name)
                            .onSubmit { focus = .email }
                    }
                    Divider().padding(.leading)
                }
                HStack {
                    Image(systemName: "envelope.fill")
                        .frame(width: 20, alignment: .center)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .focused($focus, equals: .email)
                        .onSubmit { focus = .password }
                }
                Divider().padding(.leading)
                HStack {
                    Image(systemName: "key.fill")
                        .frame(width: 20, alignment: .center)
                    SecureField("Password", text: $password)
                        .textContentType(signUp ? .newPassword : .password)
                        .focused($focus, equals: .password)
                        .onSubmit { focus = signUp ? .passwordConfirmation : nil }
                    if !signUp {
                        Button("Forgot?") {
                            loading = true
                            do {
                                try await authenticationManager.sendPasswordReset(to: email)
                                appState.hudState = .success(text: "Password reset instructions have been sent to your email")
                            } catch {
                                appState.hudState = .error(error)
                            }
                            loading = false
                        }
                        .font(.callout)
                        .disabled(loading)
                    }
                }
                if signUp {
                    Divider().padding(.leading)
                    HStack {
                        Image(systemName: "key.fill")
                            .frame(width: 20, alignment: .center)
                        SecureField("Confirm password", text: $passwordConfirmation)
                            .textContentType(.newPassword)
                            .focused($focus, equals: .passwordConfirmation)
                            .onSubmit { focus = nil }
                    }
                }
            }

            HStack {
                if loading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 20) // hmmm...minHeight required to avoid weird layout
                } else if signingInWithEmail {
                    Button("Back", systemImage: "chevron.left", toggling: $signingInWithEmail)
                        .frame(maxWidth: .infinity, minHeight: 20) // hmmm...minHeight required to avoid weird layout
                }
                
                Button(action: submit) {
                    Label(signUp ? "Sign up" : "Sign in", systemImage: "envelope.fill")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(submitDisabled)
            }
        }
    }
    
    private func submit() {
        Task { [email, password] in
            focus = nil
            loading = true
            do {
                if signUp {
                    try await authenticationManager.signUp(name: name, email: email, password: password, passwordConfirmation: passwordConfirmation)
                } else {
                    try await authenticationManager.signIn(with: .email(email, password: password))
                }
            } catch {
                appState.hudState = .error(error)
            }
            loading = false
        }
    }
}

struct EmailSignInForm_Previews: PreviewProvider {
    static var previews: some View {
        EmailSignInForm(signingInWithEmail: .constant(true))
            .setupMocks()
            .padding()
    }
}
