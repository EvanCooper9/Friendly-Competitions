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
        switch credential {
        case let .apple(id, nonce, fullName):
            let oAuthCredential = OAuthProvider.appleCredential(
                withIDToken: id,
                rawNonce: nonce,
                fullName: fullName
            )
            return signIn(with: oAuthCredential)
                .map { result -> AuthUser in result.user }
                .eraseToAnyPublisher()
        case let .email(email, password):
            return signIn(withEmail: email, password: password)
                .map { result -> AuthUser in result.user }
                .eraseToAnyPublisher()
        }
    }

    func signUp(with credential: AuthCredential) -> AnyPublisher<AuthUser, Error> {
        switch credential {
        case .apple:
            return .never()
        case .email(let email, let password):
            return createUser(withEmail: email, password: password)
                .map { result -> AuthUser in result.user }
                .eraseToAnyPublisher()
        }
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
