import Combine
import Contacts
import Firebase
import FirebaseFirestore
import Resolver

final class AddFriendViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published var searchResults = [User]()

    var searchText = "" {
        didSet {
            searchTask = Task { try await searchUsers() }
        }
    }

    // MARK: - Private Properties

    private var sharedFriendId: String?
    private var searchTask: Task<Void, Error>? {
        willSet { searchTask?.cancel() }
    }

    @LazyInjected private var contactsProvider: ContactsManaging
    @LazyInjected private var database: Firestore
    @LazyInjected private var user: User

    // MARK: - Lifecycle

    init() {
//        database.collection("users")
//            .whereField("id", isNotEqualTo: user.id)
//            .addSnapshotListener { snapshot, error in
//                let allUsers = snapshot?.documents.decoded(asArrayOf: User.self)
//                    .filter { user in
//                        // hide friends that exist already
//                        guard !user.friends.contains(self.user.id) else { return false }
//
//                        // show friends who come from a shared id, regardless of contact info.
//                        guard user.id != self.sharedFriendId else { return true }
//
//                        // return only those in local contacts
//                        return self.contactsProvider.contacts.contains {
//                            $0.emailAddresses
//                                .map(\.value)
//                                .contains(user.email as NSString)
//                        }
//                    } ?? []
//
//                self.allUsers = allUsers
//                self.selectedUsers = allUsers.filter { self.user.outgoingFriendRequests.contains($0.id) }
//            }
    }

    // MARK: - Public Methods

    func setup(sharedFriendId: String?) {
        guard let sharedFriendId = sharedFriendId else { return }
        Task {
            let user = try await database.document("users/\(sharedFriendId)")
                .getDocument()
                .decoded(as: User.self)
            DispatchQueue.main.async {
                self.searchResults = [user]
            }
        }
    }

    func tapped(contact: User) {
        let batch = database.batch()

        let myRequests = user.outgoingFriendRequests.contains(contact.id) ?
            user.outgoingFriendRequests.removing(contact.id) :
            user.outgoingFriendRequests.appending(contact.id)
        batch.updateData(["outgoingFriendRequests": myRequests], forDocument: database.document("users/\(user.id)"))

        let theirRequests = contact.incomingFriendRequests.contains(user.id) ?
            contact.incomingFriendRequests.removing(user.id) :
            contact.incomingFriendRequests.appending(user.id)
        batch.updateData(["incomingFriendRequests": theirRequests], forDocument: database.document("users/\(contact.id)"))

        batch.commit()
    }

    // MARK: - Private Methods

    private func searchUsers() async throws {
        guard !searchText.isEmpty else {
            searchResults.removeAll()
            return
        }
        let users = try await database.collection("users")
            .getDocuments()
            .documents
            .decoded(asArrayOf: User.self)
            .filter { someUser in
                guard someUser.name.starts(with: searchText) else { return false }
                return !user.friends
                    .appending(user.id)
                    .contains { $0 == someUser.id }
            }
            .sorted(by: \.name)
        print(users.map(\.name))
        try Task.checkCancellation()
        DispatchQueue.main.async {
            self.searchResults = users
        }
    }
}
