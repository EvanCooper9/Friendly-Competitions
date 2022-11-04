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

    var emailVerified: AnyPublisher<Bool, Never> { _emailVerified.eraseToAnyPublisher() }
    var loggedIn: AnyPublisher<Bool, Never> { _loggedIn.eraseToAnyPublisher() }

    // MARK: - Private Properties

    @LazyInjected(Container.database) private var database

    @UserDefault("current_user") private var currentUser: User? = nil

    private var _emailVerified: CurrentValueSubject<Bool, Never>!
    private var _loggedIn: CurrentValueSubject<Bool, Never>!

    private var currentNonce: String?
    private var userListener: AnyCancellable?
    private var signInWithAppleSubject: PassthroughSubject<Void, Error>?

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    override init() {
        super.init()
        try! Auth.auth().useUserAccessGroup(Bundle.main.bundleIdentifier!)

        _emailVerified = .init(Auth.auth().currentUser?.isEmailVerified ?? false)
        _loggedIn = .init(currentUser != nil)

        if let currentUser {
            registerUserManager(with: currentUser)
        }
        
        $currentUser
            .removeDuplicates { $0?.id == $1?.id }
            .dropFirst()
            .sink(withUnretained: self) { strongSelf, user in
                if let user = user {
                    strongSelf.registerUserManager(with: user)
                } else {
                    Container.userManager.reset()
                }
                strongSelf._loggedIn.send(user != nil)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods
    
    func signIn(with signInMethod: SignInMethod) -> AnyPublisher<Void, Error> {
        let publisher: AnyPublisher<Void, Error>
        switch signInMethod {
        case .apple:
            publisher = signInWithApple()
        case .email(let email, let password):
            publisher = signIn(email: email, password: password)
        }
        
        return publisher
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf in
                guard let firebaseUser = Auth.auth().currentUser else { return }
                Task {
                    let user = try await self.database.document("users/\(firebaseUser.uid)").getDocument().decoded(as: User.self)
                    DispatchQueue.main.async {
                        self.currentUser = user
                        self._emailVerified.send(firebaseUser.isEmailVerified || firebaseUser.email == "review@apple.com")
                    }
                }
            })
            .eraseToAnyPublisher()
    }
    
    func signUp(name: String, email: String, password: String, passwordConfirmation: String) -> AnyPublisher<Void, Error> {
        guard password == passwordConfirmation else { return .error(SignUpError.passwordMatch) }
        return .fromAsync { [weak self] in
            guard let self = self else { return }
            let firebaseUser = try await Auth.auth().createUser(withEmail: email, password: password).user
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            try await self.updateFirestoreUserWithAuthUser(firebaseUser)
            try await firebaseUser.sendEmailVerification()
        }
    }
    
    func checkEmailVerification() -> AnyPublisher<Void, Error> {
        .fromAsync { [weak self] in
            guard let self = self, let firebaseUser = Auth.auth().currentUser else { return }
            try await firebaseUser.reload()
            self._emailVerified.send(firebaseUser.isEmailVerified)
        }
    }
    
    func resendEmailVerification() -> AnyPublisher<Void, Error> {
        .fromAsync {
            try await Auth.auth().currentUser?.sendEmailVerification()
        }
    }
    
    func sendPasswordReset(to email: String) -> AnyPublisher<Void, Error> {
        .fromAsync { [email] in
            try await Auth.auth().sendPasswordReset(withEmail: email)
        }
    }
    
    func deleteAccount() -> AnyPublisher<Void, Error> {
        .fromAsync {
            try await Auth.auth().currentUser?.delete()
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        _emailVerified.send(false)
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
    
    private func signIn(email: String, password: String) -> AnyPublisher<Void, Error> {
        .fromAsync {
            try await Auth.auth().signIn(withEmail: email, password: password)
        }
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
