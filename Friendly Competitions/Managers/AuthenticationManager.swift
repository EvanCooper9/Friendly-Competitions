import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Resolver
import SwiftUI

class AnyAuthenticationManager: ObservableObject {
    @AppStorage("loggedIn") var loggedIn = false
}

final class AuthenticationManager: AnyAuthenticationManager {

    @LazyInjected private var database: Firestore
    
    @Published(storedWithKey: "currentUser") private var currentUser: User? = nil

    override init() {
        super.init()
        listenForAuth()
        if loggedIn, let currentUser = currentUser {
            registerUserManager(with: currentUser)
        }
    }

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
                    self.currentUser = user
                    self.loggedIn = true
                }
            }
        }
    }

    private func registerUserManager(with user: User) {
        Resolver.register { UserManager(user: user) as AnyUserManager }.scope(.application)
    }
}
