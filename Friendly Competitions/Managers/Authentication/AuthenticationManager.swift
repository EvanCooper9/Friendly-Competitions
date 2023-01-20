import AuthenticationServices
import Combine
import CryptoKit
import ECKit
import ECKit_Firebase
import Factory
import Firebase
import FirebaseAuthCombineSwift
import FirebaseFirestore
import SwiftUI

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

    @LazyInjected(Container.database) private var database

    @UserDefault("current_user") private var currentUser: User?

    private var emailVerifiedSubject: CurrentValueSubject<Bool, Never>!
    private var loggedInSubject: CurrentValueSubject<Bool, Never>!

    private var currentNonce: String?
    private var userListener: AnyCancellable?
    private var signInWithAppleSubject: PassthroughSubject<Void, Error>?

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    override init() {
        super.init()
        
        emailVerifiedSubject = .init(Auth.auth().currentUser?.isEmailVerified ?? false)
        loggedInSubject = .init(currentUser != nil)

        if let currentUser {
            registerUserManager(with: currentUser)
        }
        
        $currentUser
            .removeDuplicates { $0?.id == $1?.id }
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink(withUnretained: self) { strongSelf, user in
                if let user = user {
                    strongSelf.registerUserManager(with: user)
                } else {
                    Container.userManager.reset()
                }
                strongSelf.loggedInSubject.send(user != nil)
            }
            .store(in: &cancellables)

        listenForAuth()
    }

    // MARK: - Public Methods
    
    func signIn(with signInMethod: SignInMethod) -> AnyPublisher<Void, Error> {
        switch signInMethod {
        case .apple:
            return signInWithApple()
        case .email(let email, let password):
            return Auth.auth()
                .signIn(withEmail: email, password: password)
                .print("sign in with email")
                .mapToVoid()
                .eraseToAnyPublisher()
        }
    }
    
    func signUp(name: String, email: String, password: String, passwordConfirmation: String) -> AnyPublisher<Void, Error> {
        guard password == passwordConfirmation else { return .error(SignUpError.passwordMatch) }
        return Auth.auth()
            .createUser(withEmail: email, password: password)
            .map(\.user)
            .flatMapAsync { [weak self] user in
                guard let strongSelf = self else { return }
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = name
                try await changeRequest.commitChanges()
                try await strongSelf.updateFirestoreUserWithAuthUser(user)
                try await user.sendEmailVerification()
            }
            .eraseToAnyPublisher()
    }
    
    func checkEmailVerification() -> AnyPublisher<Void, Error> {
        guard let firebaseUser = Auth.auth().currentUser else { return .just(()) }
        return .fromAsync { try await firebaseUser.reload() }
            .receive(on: RunLoop.main)
            .handleEvents(withUnretained: self, receiveOutput: { $0.emailVerifiedSubject.send(firebaseUser.isEmailVerified) })
            .eraseToAnyPublisher()
    }
    
    func resendEmailVerification() -> AnyPublisher<Void, Error> {
        guard let user = Auth.auth().currentUser else { return .just(()) }
        return user.sendEmailVerification().eraseToAnyPublisher()
    }
    
    func sendPasswordReset(to email: String) -> AnyPublisher<Void, Error> {
        Auth.auth()
            .sendPasswordReset(withEmail: email)
            .eraseToAnyPublisher()
    }
    
    func deleteAccount() -> AnyPublisher<Void, Error> {
        .fromAsync {
            try await Auth.auth().currentUser?.delete()
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // MARK: - Private Methods
    
    private func signInWithApple() -> AnyPublisher<Void, Error> {
        let nonce = Nonce.randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()

        let subject = PassthroughSubject<Void, Error>()
        signInWithAppleSubject = subject
        return subject.eraseToAnyPublisher()
    }
    
    private func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    private func listenForAuth() {
        Auth.auth()
            .authStateDidChangePublisher()
            .print("auth state did change")
            .sinkAsync { [weak self] firebaseUser in
                guard let firebaseUser = firebaseUser else {
                    self?.currentUser = nil
                    self?.userListener = nil
                    return
                }
                
                try await self?.updateFirestoreUserWithAuthUser(firebaseUser)
            }
            .store(in: &cancellables)
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }

    private func registerUserManager(with user: User) {
        Container.userManager.register { [weak self] in
            guard let strongSelf = self else { fatalError("This should not happen") }
            let userManager = UserManager(user: user)
            strongSelf.userListener = userManager.userPublisher
                .receive(on: RunLoop.main)
                .map(User?.init)
                .assign(to: \.currentUser, on: strongSelf, ownership: .weak)
            return userManager
        }
    }
    
    private func updateFirestoreUserWithAuthUser(_ firebaseUser: FirebaseAuth.User) async throws {
        guard let email = firebaseUser.email else { return }
        let name = firebaseUser.displayName ?? ""
        let userJson = [
            "id": firebaseUser.uid,
            "email": email,
            "name": name
        ]
        
        do {
            try await database.document("users/\(firebaseUser.uid)").updateData(userJson)
        } catch {
            guard let nsError = error as NSError?, nsError.domain == "FIRFirestoreErrorDomain", nsError.code == 5 else { return }
            let user = User(id: firebaseUser.uid, email: email, name: name)
            try await database.document("users/\(user.id)").setDataEncodable(user)
        }
        
        let user = try await self.database.document("users/\(firebaseUser.uid)").getDocument().data(as: User.self)
        DispatchQueue.main.async {
            self.currentUser = user
            self.emailVerifiedSubject.send(firebaseUser.isEmailVerified || firebaseUser.email == "review@apple.com")
        }
    }
}

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleIDCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else { return }
        
        let appleIDName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idToken, rawNonce: currentNonce)

        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let firebaseUser = authResult?.user else { return }
            let displayName = appleIDName.nilIfEmpty ?? firebaseUser.displayName ?? ""
            guard firebaseUser.displayName != displayName else { return }
            
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = displayName
            changeRequest.commitChanges { [weak self] error in
                Task { [weak self] in
                    try await self?.updateFirestoreUserWithAuthUser(firebaseUser)
                }
            }
        }
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
