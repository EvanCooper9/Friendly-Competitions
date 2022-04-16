import AuthenticationServices
import Combine
import CryptoKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Resolver
import SwiftUI

enum SignInMethod {
    case apple
    case email(_ email: String, password: String)
}

enum SignUpError: LocalizedError {
    case passwordMatch
    
    var errorDescription: String? { localizedDescription }
    var localizedDescription: String {
        switch self {
        case .passwordMatch:
            return "Passwords do not match"
        }
    }
}

class AnyAuthenticationManager: NSObject, ObservableObject {
    @AppStorage("emailVerified") var emailVerified = false
    @AppStorage("loggedIn") var loggedIn = false
    
    func signIn(with signInMethod: SignInMethod) async throws {}
    func signUp(name: String, email: String, password: String, passwordConfirmation: String) async throws {}
    func deleteAccount() async throws {}
    func signOut() throws {}
    
    func checkEmailVerification() async throws {}
    func resendEmailVerification() async throws {}
    func sendPasswordReset(to email: String) async throws {}
}

final class AuthenticationManager: AnyAuthenticationManager {

    @LazyInjected private var database: Firestore
    
    @Published(storedWithKey: .currentUser) private var currentUser: User? = nil
    
    private var currentNonce: String?
    private var userListener: AnyCancellable?

    override init() {
        super.init()
        listenForAuth()
        
        if let firebaseUser = Auth.auth().currentUser, let currentUser = currentUser {
            emailVerified = firebaseUser.isEmailVerified
            loggedIn = true
            registerUserManager(with: currentUser)
        } else {
            emailVerified = false
            loggedIn = false
        }
    }
    
    override func signIn(with signInMethod: SignInMethod) async throws {
        switch signInMethod {
        case .apple:
            signInWithApple()
        case .email(let email, let password):
            try await signIn(email: email, password: password)
        }
    }
    
    override func signUp(name: String, email: String, password: String, passwordConfirmation: String) async throws {
        guard password == passwordConfirmation else { throw SignUpError.passwordMatch }
        let firebaseUser = try await Auth.auth().createUser(withEmail: email, password: password).user
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        try await updateFirestoreUserWithAuthUser(firebaseUser)
        try await firebaseUser.sendEmailVerification()
    }
    
    override func checkEmailVerification() async throws {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        try await firebaseUser.reload()
        DispatchQueue.main.async { [weak self] in
            self?.emailVerified = firebaseUser.isEmailVerified
        }
    }
    
    override func resendEmailVerification() async throws {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        try await firebaseUser.sendEmailVerification()
    }
    
    override func sendPasswordReset(to email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    override func deleteAccount() async throws {
        try await Auth.auth().currentUser?.delete()
    }

    override func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // MARK: - Private Methods
    
    private func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
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
                    self.loggedIn = false
                }
                return
            }
            
            Task {
                try await self.updateFirestoreUserWithAuthUser(firebaseUser)
                let user = try await self.database.document("users/\(firebaseUser.uid)").getDocument().decoded(as: User.self)
                self.registerUserManager(with: user)
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.emailVerified = firebaseUser.isEmailVerified
                    self.loggedIn = true
                }
            }
        }
    }
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess { fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)") }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
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
        Resolver.register(AnyUserManager.self) { [weak self, user] in
            let userManager = UserManager(user: user)
            self?.userListener = userManager.$user
                .sink { [weak self] user in
                    DispatchQueue.main.async {
                        self?.currentUser = user
                    }
                }
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
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }

        // Create an account in your system.
        guard let tokenData = appleIDCredential.identityToken, let identityToken = String(data: tokenData, encoding: .utf8) else { return }

        // Initialize a Firebase credential.
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: identityToken,
            rawNonce: currentNonce
        )

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
        print("Sign in with Apple errored: \(error)")
    }
}

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        .init()
    }
}
