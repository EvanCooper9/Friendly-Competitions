import Combine
import Firebase
import FirebaseFirestore
import Resolver

class AnyUserManager: ObservableObject {
    @Published var user: User

    init(user: User) {
        self.user = user
    }

    func deleteAccount() {}
    func signOut() {}
}

final class UserManager: AnyUserManager {

    @Injected private var database: Firestore

    private var userListener: ListenerRegistration?

    override init(user: User) {
        super.init(user: user)
        listenForUser()
    }

    deinit {
        userListener?.remove()
        userListener = nil
    }

    override func deleteAccount() {
        Task {
            try await database.document("users/\(user.id)").delete()
            try await Auth.auth().currentUser?.delete()
        }
    }

    override func signOut() {
        try? Auth.auth().signOut()
    }

    private func listenForUser() {
        userListener = database.document("users/\(user.id)")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let user = try? snapshot?.decoded(as: User.self) else { return }
                DispatchQueue.main.async {
                    self.user = user
                }
            }
    }
}
