import Firebase
import FirebaseFirestore
import Resolver

final class SettingsViewModel: ObservableObject {

    @LazyInjected private var database: Firestore
    @LazyInjected private var user: User

    func deleteAccount() {
        Task {
            try await database.document("users/\(user.id)").delete()
            try await Auth.auth().currentUser?.delete()
        }
    }
}
