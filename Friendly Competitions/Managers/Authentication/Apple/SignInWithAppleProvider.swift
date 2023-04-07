import AuthenticationServices
import Combine
import ECKit
import Factory
import FirebaseAuth

// sourcery: AutoMockable
protocol SignInWithAppleProviding {
    func signIn() -> AnyPublisher<SignInWithAppleResult, Error>
}

final class SignInWithAppleProvider: NSObject, SignInWithAppleProviding {

    // MARK: - Private Properties

    private var nonce: String?

    @Injected(\.auth) private var auth

    private var signedInSubject: PassthroughSubject<SignInWithAppleResult, Error>?
    private var cancellables = Cancellables()

    // MARK: - Public Methods

    func signIn() -> AnyPublisher<SignInWithAppleResult, Error> {
        let subject = PassthroughSubject<SignInWithAppleResult, Error>()
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
            .sink(withUnretained: self) { strongSelf, authUser in
                let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                let result = SignInWithAppleResult(user: authUser, displayName: displayName)
                strongSelf.signedInSubject?.send(result)
            }
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
