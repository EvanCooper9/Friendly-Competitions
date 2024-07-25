import Algorithms
import AuthenticationServices
import Combine
import ECKit
import Factory
import FCKit
import FirebaseAuth

// sourcery: AutoMockable
protocol SignInWithAppleProviding {
    func signIn() -> AnyPublisher<AuthUser, Error>
    func link(with user: AuthUser) -> AnyPublisher<AuthUser, Error>
}

final class SignInWithAppleProvider: NSObject, SignInWithAppleProviding {

    // MARK: - Public Methods

    func signIn() -> AnyPublisher<AuthUser, Error> {
        let nonce = Nonce.randomNonceString()
        let delegate = SignInWithAppleDelegate(accountType: .new, nonce: nonce)
        return delegate.signedIn
            .handleEvents(withUnretained: self, receiveSubscription: { strongSelf, _ in
                strongSelf.startSignIn(delegate: delegate, nonce: nonce)
            })
            .eraseToAnyPublisher()
    }

    func link(with user: AuthUser) -> AnyPublisher<AuthUser, Error> {
        let nonce = Nonce.randomNonceString()
        let delegate = SignInWithAppleDelegate(accountType: .link(user: user), nonce: nonce)
        return delegate.linked
            .handleEvents(withUnretained: self, receiveSubscription: { strongSelf, _ in
                strongSelf.startSignIn(delegate: delegate, nonce: nonce)
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func startSignIn(delegate: ASAuthorizationControllerDelegate, nonce: String) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Nonce.sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension SignInWithAppleProvider: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        .init()
    }
}

private final class SignInWithAppleDelegate: NSObject, ASAuthorizationControllerDelegate {

    enum AccountType {
        case new
        case link(user: AuthUser)
    }

    let accountType: AccountType
    let nonce: String

    var linked: AnyPublisher<AuthUser, Error> { linkedSubject.eraseToAnyPublisher() }
    var signedIn: AnyPublisher<AuthUser, Error> { signedInSubject.eraseToAnyPublisher() }

    // MARK: - Private Properties

    @Injected(\.api) private var api: API
    @Injected(\.auth) private var auth: AuthProviding
    @Injected(\.environmentManager) private var environmentManager: EnvironmentManaging

    private let linkedSubject = PassthroughSubject<AuthUser, Error>()
    private let signedInSubject = PassthroughSubject<AuthUser, Error>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(accountType: AccountType, nonce: String) {
        self.accountType = accountType
        self.nonce = nonce
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleIDCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else { return }

        let credential = AuthCredential.apple(id: idToken, nonce: nonce, fullName: appleIDCredential.fullName)

        switch accountType {
        case .new:
            auth.signIn(with: credential)
                .flatMapLatest { authUser -> AnyPublisher<AuthUser, Error> in
                    let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compacted()
                        .joined(separator: " ")

                    // The display name will be empty after the first sign in. Make sure not to update
                    // the auth user's display name if empty (or the same).
                    // https://firebase.google.com/docs/auth/ios/apple
                    guard !displayName.isEmpty, displayName != authUser.displayName else { return .just(authUser) }
                    return authUser.set(displayName: displayName)
                }
                .flatMapLatest(withUnretained: self) { strongSelf, user -> AnyPublisher<AuthUser, Error> in
                    strongSelf
                        .save(authorizationCode: appleIDCredential.authorizationCode)
                        .mapToValue(user)
                        .eraseToAnyPublisher()
                }
                .first()
                .sink(withUnretained: self, receiveCompletion: { strongSelf, completion in
                    strongSelf.signedInSubject.send(completion: completion)
                }, receiveValue: { strongSelf, user in
                    strongSelf.signedInSubject.send(user)
                })
                .store(in: &cancellables)
        case .link(let user):
            user.link(with: credential)
                .flatMapLatest { _ -> AnyPublisher<AuthUser, Error> in
                    let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compacted()
                        .joined(separator: " ")

                    // The display name will be empty after the first sign in. Make sure not to update
                    // the auth user's display name if empty (or the same).
                    // https://firebase.google.com/docs/auth/ios/apple
                    guard !displayName.isEmpty, displayName != user.displayName else { return .just(user) }
                    return user.set(displayName: displayName)
                }
                .flatMapLatest(withUnretained: self) { strongSelf, user -> AnyPublisher<AuthUser, Error> in
                    strongSelf
                        .save(authorizationCode: appleIDCredential.authorizationCode)
                        .mapToValue(user)
                        .eraseToAnyPublisher()
                }
                .sink(withUnretained: self, receiveCompletion: { strongSelf, completion in
                    strongSelf.linkedSubject.send(completion: completion)
                }, receiveValue: { strongSelf, user in
                    strongSelf.linkedSubject.send(user)
                })
                .store(in: &cancellables)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signedInSubject.send(completion: .failure(error))
    }

    // MARK: - Private Methods

    private func save(authorizationCode: Data?) -> AnyPublisher<Void, Error> {
        guard let authorizationCode,
              let code = String(data: authorizationCode, encoding: .utf8)
        else { return .just(()) }

        return api
            .call(.saveSWAToken(code: code))
            .catchErrorJustReturn(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
