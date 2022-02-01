import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Resolver

class AnyUserManager: ObservableObject {
    func deleteAccount() {}
    func signOut() {}
}

final class UserManager: AnyUserManager {

    @LazyInjected private var database: Firestore
    @LazyInjected private var user: User

    override func deleteAccount() {
        Task {
            try await database.document("users/\(user.id)").delete()
            try await Auth.auth().currentUser?.delete()
        }
    }

    override func signOut() {
        try? Auth.auth().signOut()
    }
}
