import AuthenticationServices
import Combine
import ECKit
import Factory
import FirebaseAuth

// sourcery: AutoMockable
protocol SignInWithAppleProviding {
    func signIn() -> AnyPublisher<AuthUser, Error>
}

final class SignInWithAppleProvider: NSObject, SignInWithAppleProviding {

    // MARK: - Private Properties

    private var nonce: String?

    @Injected(\.auth) private var auth
    @Injected(\.environmentManager) private var environmentManager

    private var signedInSubject: PassthroughSubject<AuthUser, Error>?
    private var cancellables = Cancellables()

    // MARK: - Public Methods

    func signIn() -> AnyPublisher<AuthUser, Error> {
        let subject = PassthroughSubject<AuthUser, Error>()
        signedInSubject = subject
        return subject
            .first()
            .eraseToAnyPublisher()
            .handleEvents(withUnretained: self, receiveSubscription: { strongSelf, _ in
                strongSelf.startSignIn()
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func startSignIn() {
        let nonce = Nonce.randomNonceString()
        self.nonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Nonce.sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension SignInWithAppleProvider: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleIDCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else { return }

        let credential = AuthCredential.apple(id: idToken, nonce: nonce, fullName: appleIDCredential.fullName)

        auth.signIn(with: credential)
            .flatMapLatest(withUnretained: self) { strongSelf, authUser -> AnyPublisher<AuthUser, Error> in

                // For some reason, the firebase auth emulator doesn't handle the fullName passed to the
                // credential when signing in with Apple (above). This is handled correctly in prod.
                // Assuming this is just a lack of feature parity since the iOS SDK had this API added in 10.7.0.
                // https://firebase.google.com/support/release-notes/ios#10.7.0
                guard strongSelf.environmentManager.environment.isDebug else { return .just(authUser) }

                let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                // The display name will be empty after the first sign in. Make sure not to update
                // the auth user's display name if empty (or the same).
                // https://firebase.google.com/docs/auth/ios/apple
                guard !displayName.isEmpty, displayName != authUser.displayName else { return .just(authUser) }
                return authUser.set(displayName: displayName)
            }
            .first()
            .sink(withUnretained: self) { $0.signedInSubject?.send($1) }
            .store(in: &cancellables)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signedInSubject?.send(completion: .failure(error))
    }
}

extension SignInWithAppleProvider: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        .init()
    }
}
