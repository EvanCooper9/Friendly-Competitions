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
    
    @StateObject private var appState = Resolver.resolve(AppState.self)
    @StateObject private var authenticationManager = Resolver.resolve(AnyAuthenticationManager.self)
    
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
                Button(signUp ? "Sign in" : "Sign up") {
                    signUp.toggle()
                    focus = signUp ? .name : .email
                }
            }
            .padding(.trailing)
            .font(.callout)
            .disabled(loading)
            
            VStack(spacing: 5) {
                if signUp {
                    inputField {
                        Image(systemName: "person.fill")
                            .frame(width: 20, alignment: .center)
                            .foregroundColor(.gray)
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .focused($focus, equals: .name)
                            .onSubmit { focus = .email }
                    }
                }
                inputField {
                    Image(systemName: "envelope.fill")
                        .frame(width: 20, alignment: .center)
                        .foregroundColor(.gray)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .focused($focus, equals: .email)
                        .onSubmit { focus = .password }
                }
                inputField {
                    Image(systemName: "key.fill")
                        .frame(width: 20, alignment: .center)
                        .foregroundColor(.gray)
                    SecureField("Password", text: $password)
                        .textContentType(signUp ? .newPassword : .password)
                        .focused($focus, equals: .password)
                        .onSubmit { focus = signUp ? .passwordConfirmation : nil }
                    if !signUp {
                        Button(systemImage: "questionmark.circle") {
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
                    inputField {
                        Image(systemName: "key.fill")
                            .frame(width: 20, alignment: .center)
                            .foregroundColor(.gray)
                        SecureField("Confirm password", text: $passwordConfirmation)
                            .textContentType(.newPassword)
                            .focused($focus, equals: .passwordConfirmation)
                            .onSubmit { focus = nil }
                    }
                }
            }

            HStack {
                Group {
                    if loading {
                        ProgressView()
                    } else if signingInWithEmail {
                        Button("Back", systemImage: "chevron.left", toggling: $signingInWithEmail)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 20) // hmmm...minHeight required to avoid weird layout
                
                Button(action: submit) {
                    Label(signUp ? "Sign up" : "Sign in", systemImage: "envelope.fill")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(submitDisabled)
            }
        }
        .onAppear { focus = .email }
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
    
    @ViewBuilder
    private func inputField<Content: View>(@ViewBuilder inputContent: () -> Content) -> some View {
        HStack {
            inputContent()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .overlay(
            Capsule()
                .stroke(lineWidth: 0.15)
        )
    }
}

struct EmailSignInForm_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 242/255, green: 242/255, blue: 247/255) // background used on sign in
                .ignoresSafeArea()
            EmailSignInForm(signingInWithEmail: .constant(true))
                .setupMocks()
                .padding()
        }
    }
}
