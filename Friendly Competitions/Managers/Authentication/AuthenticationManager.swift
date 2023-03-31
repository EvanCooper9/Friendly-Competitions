import AuthenticationServices
import Combine
import CryptoKit
import ECKit
import Factory
import Firebase
import FirebaseAuthCombineSwift
import SwiftUI

enum AuthenticationError: Error {
    case missingEmail
}

// sourcery: AutoMockable
protocol AuthenticationManaging {
    var emailVerified: AnyPublisher<Bool, Never> { get }
    var loggedIn: AnyPublisher<Bool, Never> { get }

    func signIn(with signInMethod: SignInMethod) -> AnyPublisher<Void, Error>
    func signUp(name: String, email: String, password: String, passwordConfirmation: String) -> AnyPublisher<Void, Error>
    func deleteAccount() -> AnyPublisher<Void, Error>
    func signOut() throws

    func checkEmailVerification() -> AnyPublisher<Void, Error>
    func resendEmailVerification() -> AnyPublisher<Void, Error>
    func sendPasswordReset(to email: String) -> AnyPublisher<Void, Error>
}

final class AuthenticationManager: NSObject, AuthenticationManaging {

    // MARK: - Public Properties

    var emailVerified: AnyPublisher<Bool, Never> { emailVerifiedSubject.eraseToAnyPublisher() }
    var loggedIn: AnyPublisher<Bool, Never> { loggedInSubject.eraseToAnyPublisher() }

    // MARK: - Private Properties

    @Injected(\.auth) private var auth
    @Injected(\.authenticationCache) private var authenticationCache
    @Injected(\.database) private var database

    private var emailVerifiedSubject: CurrentValueSubject<Bool, Never>!
    private var loggedInSubject: CurrentValueSubject<Bool, Never>!

    private var currentNonce: String?
    private var userListener: AnyCancellable?
    private var signInWithAppleSubject: PassthroughSubject<Void, Error>?
    private let createdUserSubject = PassthroughSubject<User, Error>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    override init() {
        super.init()

        emailVerifiedSubject = .init(auth.currentUser?.isEmailVerified ?? false)
        loggedInSubject = .init(authenticationCache.user != nil)

        if let user = authenticationCache.user {
            registerUserManager(with: user)
        }

        listenForAuth()
    }

    // MARK: - Public Methods

    func signIn(with signInMethod: SignInMethod) -> AnyPublisher<Void, Error> {
        switch signInMethod {
        case .apple:
            return signInWithApple()
        case .email(let email, let password):
            return auth.signIn(withEmail: email, password: password)
                .mapToVoid()
                .eraseToAnyPublisher()
        }
    }

    func signUp(name: String, email: String, password: String, passwordConfirmation: String) -> AnyPublisher<Void, Error> {
        guard password == passwordConfirmation else { return .error(SignUpError.passwordMatch) }
        return auth.createUser(withEmail: email, password: password)
            .map(\.user)
            .flatMapLatest(withUnretained: self) { $0.update(displayName: name, for: $1) }
            .flatMapLatest { firebaseUser in
                firebaseUser.sendEmailVerification()
                    .mapToValue(firebaseUser)
                    .eraseToAnyPublisher()
            }
            .flatMapLatest(withUnretained: self) { $0.createUser(from: $1) }
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func checkEmailVerification() -> AnyPublisher<Void, Error> {
        guard let firebaseUser = auth.currentUser else { return .just(()) }
        return .fromAsync { try await firebaseUser.reload() }
            .handleEvents(withUnretained: self, receiveOutput: { $0.emailVerifiedSubject.send(firebaseUser.isEmailVerified) })
            .eraseToAnyPublisher()
    }

    func resendEmailVerification() -> AnyPublisher<Void, Error> {
        guard let user = auth.currentUser else { return .just(()) }
        return user.sendEmailVerification().eraseToAnyPublisher()
    }

    func sendPasswordReset(to email: String) -> AnyPublisher<Void, Error> {
        auth
            .sendPasswordReset(withEmail: email)
            .eraseToAnyPublisher()
    }

    func deleteAccount() -> AnyPublisher<Void, Error> {
        .fromAsync { [weak self] in
            try await self?.auth.currentUser?.delete()
        }
    }

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Private Methods

    private func signInWithApple() -> AnyPublisher<Void, Error> {
        let nonce = Nonce.randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Nonce.sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()

        let subject = PassthroughSubject<Void, Error>()
        signInWithAppleSubject = subject
        return subject.eraseToAnyPublisher()
    }

    private func listenForAuth() {
        auth.authStateDidChangePublisher()
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf, firebaseUser in
                strongSelf.emailVerifiedSubject.send(firebaseUser?.isEmailVerified ?? false)
            })
            .flatMapLatest(withUnretained: self) { (strongSelf: AuthenticationManager, firebaseUser) -> AnyPublisher<User?, Never> in
                guard let firebaseUser else { return .just(nil) }
                let document = strongSelf.database.document("users/\(firebaseUser.uid)")
                return document.exists.flatMap { exists in
                    if exists {
                        return document.getDocument(as: User.self)
                    } else {
                        /// This is a new user, the signup methods are responsible for creating the user
                        /// in the database. Listen for that update here.
                        return strongSelf.createdUserSubject.eraseToAnyPublisher()
                    }
                }
                .asOptional()
                .catchErrorJustReturn(nil)
                .eraseToAnyPublisher()
            }
            .sink(withUnretained: self) { strongSelf, user in
                strongSelf.authenticationCache.user = user
                if let user {
                    strongSelf.registerUserManager(with: user)
                } else {
                    Container.shared.userManager.reset()
                }
            }
            .store(in: &cancellables)
    }

    private func registerUserManager(with user: User) {
        Container.shared.userManager.register { [weak self] in
            let userManager = UserManager(user: user)
            self?.userListener = userManager.userPublisher.sink { self?.authenticationCache.user = $0 }
            return userManager
        }
    }

    private func createUser(from firebaseUser: FirebaseAuth.User) -> AnyPublisher<User, Error> {
        guard let email = firebaseUser.email else {
            return .error(AuthenticationError.missingEmail)
        }

        let user = User(id: firebaseUser.uid, email: email, name: firebaseUser.displayName ?? "")
        return database.document("users/\(firebaseUser.uid)")
            .setData(from: user)
            .mapToValue(user)
            .handleEvents(withUnretained: self, receiveOutput: { $0.createdUserSubject.send($1) })
            .eraseToAnyPublisher()
    }

    private func update(displayName: String, for firebaseUser: FirebaseAuth.User) -> AnyPublisher<FirebaseAuth.User, Error> {
        guard !displayName.isEmpty, displayName != firebaseUser.displayName else { return .just(firebaseUser) }
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.displayName = displayName
        return Future { [weak self] promise in
            changeRequest.commitChanges { error in
                if let error {
                    promise(.failure(error))
                } else {
                    var user = self?.auth.currentUser ?? firebaseUser
                    promise(.success((user)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleIDCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else { return }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: currentNonce,
            fullName: appleIDCredential.fullName
        )

        auth.signIn(with: credential)
            .map(\.user)
            .flatMapLatest(withUnretained: self) { strongSelf, firebaseUser -> AnyPublisher<FirebaseAuth.User, Error> in
                let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                return strongSelf.update(displayName: displayName, for: firebaseUser)
            }
            .flatMapLatest(withUnretained: self) { strongSelf, firebaseUser -> AnyPublisher<Void, Error> in
                let document = strongSelf.database.document("users/\(firebaseUser.uid)")
                return document.exists.flatMap { exists -> AnyPublisher<Void, Error> in
                    guard !exists else { return .just(()) }
                    return strongSelf.createUser(from: firebaseUser)
                        .mapToVoid()
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            }
            .sink()
            .store(in: &cancellables)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signInWithAppleSubject?.send(completion: .failure(error))
    }
}

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        .init()
    }
}
