import Firebase
import FirebaseFirestore
import Resolver

final class ProfileViewModel: ObservableObject {

    @Injected private var database: Firestore
    @Injected private var user: User

    func deleteAccount() {
        Task {
            try await database.document("users/\(user.id)").delete()
            try await Auth.auth().currentUser?.delete()
        }
    }
}
