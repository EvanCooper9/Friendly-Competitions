enum AuthenticationMethod {
    case anonymous
    case apple
    case email(_ email: String, password: String)
}
