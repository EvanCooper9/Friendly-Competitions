import Resolver
import SwiftUI

struct EmailSignInForm: View {
    
    @Binding var signingInWithEmail: Bool
    
    @InjectedObject private var authenticationManager: AnyAuthenticationManager
    
    @State private var signUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    
    private var submitDisabled: Bool {
        let signInConditions = email.isEmpty || password.isEmpty
        let signUpContiditions = signInConditions || name.isEmpty || passwordConfirmation.isEmpty
        return signUp ? signUpContiditions : signInConditions
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Text("\(signUp ? "Have" : "Need") an account?")
                    .foregroundColor(.gray)
                Button(toggling: $signUp) {
                    Text(signUp ? "Sign in" : "Sign up")
                }
            }
            .font(.footnote)
            .padding(.trailing)
            
            VStack(spacing: 5) {
                if signUp {
                    HStack {
                        Image(systemName: "person.fill")
                            .frame(width: 20, alignment: .center)
                        TextField("Name", text: $name)
                    }
                    Divider()
                        .padding(.leading)
                }
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
                HStack {
                    Image(systemName: "key.fill")
                        .frame(width: 20, alignment: .center)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .onSubmit(submit)
                }
                if signUp {
                    Divider()
                        .padding(.leading)
                    HStack {
                        Image(systemName: "key.fill")
                            .frame(width: 20, alignment: .center)
                        SecureField("Confirm password", text: $passwordConfirmation)
                            .textContentType(.password)
                            .onSubmit(submit)
                    }
                }
            }
            .padding(.leading, 20)

            HStack {
                if signingInWithEmail {
                    Button(toggling: $signingInWithEmail) {
                        Label("Back", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity)
                    }
                }
                Button(action: submit) {
                    Label(signUp ? "Sign up" : "Sign in", systemImage: "envelope.fill")
                        .font(.title2.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .disabled(submitDisabled)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func submit() {
        guard !submitDisabled else { return }
        Task {
            if signUp {
                try await authenticationManager.signUp(name: name, email: email, password: password, passwordConfirmation: passwordConfirmation)
            } else {
                try await authenticationManager.signIn(with: .email(email, password: password))
            }
        }
    }
}

struct EmailSignInForm_Previews: PreviewProvider {
    static var previews: some View {
        EmailSignInForm(signingInWithEmail: .constant(true))
            .withEnvironmentObjects()
            .padding()
    }
}
