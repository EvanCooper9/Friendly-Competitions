import AuthenticationServices
import Combine
import CryptoKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Resolver
import SwiftUI

class AnyAuthenticationManager: NSObject, ObservableObject {
    @AppStorage("loggedIn") var loggedIn = false
    
    func signInWithApple() {}
    func signIn(email: String, password: String) {}
}

final class AuthenticationManager: AnyAuthenticationManager {

    @Injected private var database: Firestore
    
    @Published(storedWithKey: "currentUser") private var currentUser: User? = nil
    
    private var currentNonce: String?
    private var userListener: AnyCancellable?

    override init() {
        super.init()
        listenForAuth()
        if loggedIn, let currentUser = currentUser {
            registerUserManager(with: currentUser)
        }
    }
    
    override func signInWithApple() {
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
    
    override func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print(error)
                return
            }
            
            guard let firebaseUser = result?.user else { return }
            self?.updateFirestoreUserWithAuthUser(firebaseUser, email: email, displayName: "Test User")
        }
    }
    
    // MARK: - Private Methods
    
    private func listenForAuth() {
        Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            guard let self = self else { return }

            guard let firebaseUser = firebaseUser else {
                DispatchQueue.main.async {
                    self.currentUser = nil
                    self.loggedIn = false
                }
                return
            }

            Task {
                let user = try await self.database.document("users/\(firebaseUser.uid)").getDocument().decoded(as: User.self)
                self.registerUserManager(with: user)
                DispatchQueue.main.async {
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
        let existingUserManager = Resolver.optional(AnyUserManager.self)
        guard existingUserManager == nil || existingUserManager?.user.id != user.id else { return }
        
        let userManager = UserManager(user: user)
        userListener = userManager.$user
            .sink { [weak self] user in
                DispatchQueue.main.async {
                    self?.currentUser = user
                }
            }
        Resolver.register(AnyUserManager.self) { userManager }.scope(.application)
    }
    
    private func updateFirestoreUserWithAuthUser(_ firebaseUser: FirebaseAuth.User, email: String, displayName: String) {
        let userJson = [
            "id": firebaseUser.uid,
            "email": email,
            "name": displayName
        ]
        database.document("users/\(firebaseUser.uid)").updateData(userJson) { [weak self] error in
            guard let nsError = error as NSError?,
                nsError.domain == "FIRFirestoreErrorDomain",
                nsError.code == 5 else { return }
            let user = User(id: firebaseUser.uid, email: email, name: displayName)
            try? self?.database.document("users/\(user.id)").setDataEncodable(user, completion: nil)
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

//        isLoading = true

        // Sign in with Firebase.
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in

//            defer {
//                self?.isLoading = false
//            }

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
