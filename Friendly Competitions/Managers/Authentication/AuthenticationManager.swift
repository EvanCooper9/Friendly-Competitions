import AuthenticationServices
import Combine
import CryptoKit
import ECKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Resolver
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
    let loggedIn: AnyPublisher<Bool, Never>

    // MARK: - Private Properties

    @LazyInjected private var database: Firestore

    @UserDefault("current_user") private var currentUser: User? = nil

    private let _emailVerified: CurrentValueSubject<Bool, Never>

    private var currentNonce: String?
    private var userListener: AnyCancellable?
    private var signInWithAppleSubject: PassthroughSubject<Void, Error>?

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    override init() {
        if let firebaseUser = Auth.auth().currentUser {
            _emailVerified = .init(firebaseUser.isEmailVerified)
        } else {
            _emailVerified = .init(false)
        }

        let loggedInPublisher = PassthroughSubject<Bool, Never>()
        loggedIn = loggedInPublisher
            .share(replay: 1)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()

        super.init()

        $currentUser
            .sink(withUnretained: self) { strongSelf, currentUser in
                if let currentUser = currentUser {
                    strongSelf.registerUserManager(with: currentUser)
                }
                loggedInPublisher.send(currentUser != nil)
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
            return .fromAsync {
                try await Auth.auth().signIn(withEmail: email, password: password)
            }
        }
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
        Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            guard let self = self else { return }

            guard let firebaseUser = firebaseUser else {
                DispatchQueue.main.async {
                    self.currentUser = nil
                    self.userListener = nil
                }
                return
            }
            
            Task {
                try await self.updateFirestoreUserWithAuthUser(firebaseUser)
                let user = try await self.database.document("users/\(firebaseUser.uid)").getDocument().decoded(as: User.self)
                DispatchQueue.main.async {
                    self.currentUser = user
                    self._emailVerified.send(firebaseUser.isEmailVerified || firebaseUser.email == "review@apple.com")
                }
            }
        }
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    private func registerUserManager(with user: User) {
        Resolver.register(UserManaging.self) { [weak self, user] in
            guard let self = self else { fatalError("This should not happen") }
            let userManager = UserManager(user: user)
            self.userListener = userManager.user
                .receive(on: RunLoop.main)
                .map(User?.init)
                .assign(to: \.currentUser, on: self, ownership: .weak)
            return userManager
        }.scope(.shared)
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
              let tokenData = appleIDCredential.identityToken, let identityToken = String(data: tokenData, encoding: .utf8)
        else { return }

        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: identityToken, rawNonce: currentNonce)

        // Sign in with Firebase.
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            if let error = error {
                // Error. If error.code == .MissingOrInvalidNonce, make sure
                // you're sending the SHA256-hashed nonce as a hex string with
                // your request to Apple.
                print(error.localizedDescription)
                return
            }

            let name = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            let firebaseUser = Auth.auth().currentUser

            let displayName = name.isEmpty ?
                firebaseUser?.displayName ?? "" :
                name

            let changeRequest = firebaseUser?.createProfileChangeRequest()
            changeRequest?.displayName = displayName
            changeRequest?.commitChanges(completion: nil)

            guard let firebaseUser = firebaseUser, let email = appleIDCredential.email ?? firebaseUser.email else { return }
            let userJson = [
                "id": firebaseUser.uid,
                "email": email,
                "name": displayName
            ]
            self?.database.document("users/\(firebaseUser.uid)").updateData(userJson) { error in
                guard let nsError = error as NSError?,
                    nsError.domain == "FIRFirestoreErrorDomain",
                    nsError.code == 5 else { return }
                let user = User(id: firebaseUser.uid, email: email, name: displayName)
                try? self?.database.document("users/\(user.id)").setDataEncodable(user, completion: nil)
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
