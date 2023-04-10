import Combine
import CombineExt
import FirebaseAuth
import FirebaseAuthCombineSwift

extension Auth: AuthProviding {
    var user: AuthUser? {
        currentUser
    }

    func userPublisher() -> AnyPublisher<AuthUser?, Never> {
        authStateDidChangePublisher()
            .map { $0 as AuthUser? }
            .eraseToAnyPublisher()
    }

    func signIn(with credential: AuthCredential) -> AnyPublisher<AuthUser, Error> {
        let oAuthCredential: OAuthCredential
        switch credential {
        case let .apple(id, nonce, fullName):
            oAuthCredential = OAuthProvider.appleCredential(
                withIDToken: id,
                rawNonce: nonce,
                fullName: fullName
            )
        }

        return signIn(with: oAuthCredential)
            .compactMap { $0 as? AuthUser }
            .eraseToAnyPublisher()
    }

    func signIn(withEmail email: String, password: String) -> AnyPublisher<Void, Error> {
        let future: Future<AuthDataResult, Error> = signIn(withEmail: email, password: password)
        return future
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func signUp(withEmail email: String, password: String) -> AnyPublisher<AuthUser, Error> {
        createUser(withEmail: email, password: password)
            .compactMap { $0 as? AuthUser }
            .eraseToAnyPublisher()
    }

    func sendPasswordReset(to email: String) -> AnyPublisher<Void, Error> {
        sendPasswordReset(withEmail: email)
            .eraseToAnyPublisher()
    }
}

extension FirebaseAuth.User: AuthUser {

    var id: String { uid }

    func sendEmailVerification() -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            self?.sendEmailVerification { error in
                if let error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func set(displayName: String) -> AnyPublisher<AuthUser, Error> {
        let change = createProfileChangeRequest()
        change.displayName = displayName
        return Future { [weak self] promise in
            guard let self else { return }
            change.commitChanges { error in
                if let error {
                    promise(.failure(error))
                } else {
                    let user = Auth.auth().currentUser ?? self
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
