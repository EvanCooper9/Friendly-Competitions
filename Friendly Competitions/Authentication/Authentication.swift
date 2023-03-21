//import Combine
//
//// sourcery: AutoMockable
//protocol Authentication {
//    var currentUser: User? { get }
//    
//    func signIn(email: String, password: String) -> AnyPublisher<Void, Error>
//    func createUser(email: String, password: String) -> AnyPublisher<Void, Error>
//    func sendPasswordResetEmail(to email: String) -> AnyPublisher<Void, Error>
//    func signOut() -> AnyPublisher<Void, Error>
//}
//
//import FirebaseAuth
//
//extension Auth: Authentication {
//    var currentUser: User? {
//        nil
//    }
//    
//    func signIn(email: String, password: String) -> AnyPublisher<Void, Error> {
//        signIn(withEmail: email, password: password)
//            .mapToVoid()
//            .eraseToAnyPublisher()
//    }
//    
//    func createUser(email: String, password: String) -> AnyPublisher<Void, Error> {
//        createUser(withEmail: email, password: password)
//            .mapToVoid()
//            .eraseToAnyPublisher()
//    }
//    
//    func sendPasswordReset(email: String) -> AnyPublisher<Void, Error> {
//        sendPasswordReset(withEmail: email)
//            .mapToVoid()
//            .eraseToAnyPublisher()
//    }
//    
//    func signOut() -> AnyPublisher<Void, Error> {
//        do {
//            try signOut()
//            return .just(())
//        } catch {
//            return .just(error)
//        }
//    }
//}
