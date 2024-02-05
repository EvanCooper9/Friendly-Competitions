enum EmailSignInViewInputType: Equatable {
    case signIn
    case signUp

    var title: String {
        switch self {
        case .signIn:
            return L10n.SignIn.email
        case .signUp:
            return L10n.CreateAccount.email
        }
    }
}
