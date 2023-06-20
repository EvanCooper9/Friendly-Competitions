enum AuthenticationMethod: Equatable {
    case anonymous
    case apple
    case email(_ email: String, password: String)
}
