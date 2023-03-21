import SwiftUI
import SwiftUIX

struct EmailSignInForm: View {

    private enum Field: Hashable {
        case name
        case email
        case password
        case passwordConfirmation
    }

    let loading: Bool
    @Binding var signingInWithEmail: Bool
    @Binding var signUp: Bool
    @Binding var name: String
    @Binding var email: String
    @Binding var password: String
    @Binding var passwordConfirmation: String

    var onSubmit: (() -> Void)
    var onForgot: (() -> Void)

    @FocusState private var focus: Field?

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
                        Image(systemName: .personFill)
                            .frame(width: 20, alignment: .center)
                            .foregroundColor(.gray)
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .focused($focus, equals: .name)
                            .onSubmit { focus = .email }
                    }
                }
                inputField {
                    Image(systemName: .envelopeFill)
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
                        Button("", systemImage: .questionmarkCircle, action: onForgot)
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
                    } else {
                        Button("Back", systemImage: "chevron.left", toggling: $signingInWithEmail)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 20) // hmmm...minHeight required to avoid weird layout

                Button(action: onSubmit) {
                    Label(signUp ? "Sign up" : "Sign in", systemImage: .envelopeFill)
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(submitDisabled)
            }
        }
        .onAppear { focus = .email }
    }

    private func inputField<Content: View>(@ViewBuilder inputContent: () -> Content) -> some View {
        HStack {
            inputContent()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(lineWidth: 0.15)
        )
    }
}

#if DEBUG
struct EmailSignInForm_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 242/255, green: 242/255, blue: 247/255) // background used on sign in
                .ignoresSafeArea()
            EmailSignInForm(
                loading: false,
                signingInWithEmail: .constant(false),
                signUp: .constant(false),
                name: .constant(""),
                email: .constant(""),
                password: .constant(""),
                passwordConfirmation: .constant(""),
                onSubmit: {},
                onForgot: {}
            )
            .setupMocks()
            .padding()
        }
    }
}
#endif
