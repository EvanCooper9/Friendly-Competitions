import Algorithms
import AuthenticationServices
import Combine
import ECKit
import Factory
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

    @Injected(\.auth) private var auth
    @Injected(\.environmentManager) private var environmentManager

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
                .flatMapLatest(withUnretained: self) { strongSelf, authUser -> AnyPublisher<AuthUser, Error> in

                    // For some reason, the firebase auth emulator doesn't handle the fullName passed to the
                    // credential when signing in with Apple (above). This is handled correctly in prod.
                    // Assuming this is just a lack of feature parity since the iOS SDK had this API added in 10.7.0.
                    // https://firebase.google.com/support/release-notes/ios#10.7.0
                    guard strongSelf.environmentManager.environment.isDebug else { return .just(authUser) }

                    let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compacted()
                        .joined(separator: " ")

                    // The display name will be empty after the first sign in. Make sure not to update
                    // the auth user's display name if empty (or the same).
                    // https://firebase.google.com/docs/auth/ios/apple
                    guard !displayName.isEmpty, displayName != authUser.displayName else { return .just(authUser) }
                    return authUser.set(displayName: displayName)
                }
                .first()
                .sink(withUnretained: self) { $0.signedInSubject.send($1) }
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
                .sink(withUnretained: self) { $0.linkedSubject.send($1) }
                .store(in: &cancellables)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signedInSubject.send(completion: .failure(error))
    }
}
