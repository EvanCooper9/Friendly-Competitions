import Resolver
import SwiftUI

struct EmailSignInForm: View {
    
    @Binding var signingInWithEmail: Bool
    @Binding var error: Error?
    
    @InjectedObject private var authenticationManager: AnyAuthenticationManager
    
    @State private var loading = false
    @State private var signUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    
    private var submitDisabled: Bool {
        let signInConditions = email.isEmpty || password.isEmpty
        let signUpContiditions = signInConditions || name.isEmpty || passwordConfirmation.isEmpty
        return loading || (signUp ? signUpContiditions : signInConditions)
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
                }
                Divider().padding(.leading)
                HStack {
                    Image(systemName: "key.fill")
                        .frame(width: 20, alignment: .center)
                    SecureField("Password", text: $password)
                        .textContentType(signUp ? .newPassword : .password)
                        .onSubmit(submit)
                }
                if signUp {
                    Divider().padding(.leading)
                    HStack {
                        Image(systemName: "key.fill")
                            .frame(width: 20, alignment: .center)
                        SecureField("Confirm password", text: $passwordConfirmation)
                            .textContentType(.newPassword)
                            .onSubmit(submit)
                    }
                }
            }
            .disabled(loading)

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
        guard !submitDisabled else { return }
        loading = true
        Task {
            do {
                if signUp {
                    try await authenticationManager.signUp(name: name, email: email, password: password, passwordConfirmation: passwordConfirmation)
                } else {
                    try await authenticationManager.signIn(with: .email(email, password: password))
                }
            } catch {
                self.error = error
            }
            loading = false
        }
    }
}

struct EmailSignInForm_Previews: PreviewProvider {
    static var previews: some View {
        EmailSignInForm(signingInWithEmail: .constant(true), error: .constant(nil))
            .setupMocks()
            .padding()
    }
}
