enum AuthenticationMethod {
    case apple
    case email(_ email: String, password: String)
}
