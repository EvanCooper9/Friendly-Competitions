import AuthenticationServices
import CryptoKit
import FirebaseAuth
import SwiftUI
import FirebaseFirestore
import Resolver

struct SignInView: View {

    @State private var email = ""
    @State private var password = ""

    private let viewModel = SignInViewModel()

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text("Welcome")
                .font(.title)
            Text("Friendly Competitions allows you to compete with friends. Sign in or Sign up to continue.")
                .multilineTextAlignment(.center)
            Spacer()
            if viewModel.isLoading { ProgressView() }
            SignInWithAppleButton()
                .frame(maxWidth: .infinity, maxHeight: 60)
                .onTapGesture(perform: viewModel.signInWithApple)
                .disabled(viewModel.isLoading)
        }
        .padding()
    }
}

fileprivate final class SignInViewModel: NSObject, ObservableObject {

    @LazyInjected var database: Firestore

    @Published var isLoading = false

    private var currentNonce: String?

    func signInWithApple() {
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
}

extension SignInViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }

        // Create an account in your system.
        guard let tokenData = appleIDCredential.identityToken, let identityToken = String(data: tokenData, encoding: .utf8) else { return }

        // For the purpose of this demo app, store the `userIdentifier` in the keychain.
        //            self.saveUserInKeychain(userIdentifier)

        // For the purpose of this demo app, show the Apple ID credential information in the `ResultViewController`.
        //            self.showResultViewController(userIdentifier: userIdentifier, fullName: fullName, email: email)

        // Initialize a Firebase credential.
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: identityToken,
            rawNonce: currentNonce
        )

        isLoading = true

        // Sign in with Firebase.
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in

            self?.isLoading = false

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

            if !name.isEmpty {
                let user = Auth.auth().currentUser
                let changeRequest = user?.createProfileChangeRequest()
                changeRequest?.displayName = name
                changeRequest?.commitChanges(completion: nil) 

                if let user = user, let email = appleIDCredential.email {
                    let user = User(id: user.uid, email: email, name: name)
                    try? self?.database.document("users/\(user.id)").setDataEncodable(user, completion: nil)
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
    }
}

extension SignInViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        .init()
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SignInView()
        }
    }
}
