import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import Resolver
import Contacts

struct AddFriendView: View {

    @EnvironmentObject var user: User
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel: AddFriendViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        ForEach(viewModel.filteredUsers) { user in
                            HStack {
                                Text(user.name)
                                Spacer()
                                if user.incomingFriendRequests.contains(self.user.id) {
                                    Image(systemName: "clock")
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { viewModel.tapped(contact: user) }
                        }
                    } footer: {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Having trouble?")
                                Text("• Verify contacts permissions are enabled in device Settings.")
                                Text("• Verify your email in your profile from the Home screen.")
                                Button("• Or send an invite link to your friend") {
                                    guard let inviteLink = URL(string: "friendly-competitions://invite/\(user.id)") else { return }
                                    let activityVC = UIActivityViewController(activityItems: [inviteLink], applicationActivities: nil)

                                    let keyWindow = UIApplication.shared.connectedScenes
                                            .filter { $0.activationState == .foregroundActive }
                                            .compactMap { $0 as? UIWindowScene }
                                            .first?
                                            .windows
                                            .filter(\.isKeyWindow)
                                            .first

                                    keyWindow?.rootViewController?
                                        .presentedViewController?
                                        .present(activityVC, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $viewModel.searchText)
                .navigationTitle("Search for Friends")
            }
        }
    }

    init(users: [User] = [], sharedFriendId: String? = nil) {
        viewModel = .init(users: users, sharedFriendId: sharedFriendId)
    }
}

final class AddFriendViewModel: ObservableObject {

    // MARK: - Public Properties

    var searchText = "" {
        didSet {
            filteredUsers = searchText.isEmpty ?
                allUsers :
                allUsers.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    @Published var filteredUsers = [User]()
    @Published var selectedUsers = [User]()

    // MARK: - Private Properties

    @LazyInjected private var contactsProvider: ContactsManaging
    @LazyInjected private var database: Firestore
    @LazyInjected private var user: User

    private var sharedFriendId: String?

    private var allUsers: [User] {
        didSet { filteredUsers = allUsers }
    }

    // MARK: - Lifecycle
    
    init(users: [User] = [], sharedFriendId: String?) {
        allUsers = users
        filteredUsers = users

        database.collection("users")
            .whereField("id", isNotEqualTo: user.id)
            .addSnapshotListener { snapshot, error in
                let allUsers = snapshot?.documents.decoded(asArrayOf: User.self)
                    .filter { user in
                        // hide friends that exist already
                        guard !user.friends.contains(self.user.id) else { return false }

                        // show friends who come from a shared id, regardless of contact info.
                        guard user.id != self.sharedFriendId else { return true }

                        // return only those in local contacts
                        return self.contactsProvider.contacts.contains {
                            $0.emailAddresses
                                .map(\.value)
                                .contains(user.email as NSString)
                        }
                    } ?? []

                self.allUsers = allUsers
                self.selectedUsers = allUsers.filter { self.user.outgoingFriendRequests.contains($0.id) }
            }
    }

    // MARK: - Public Methods

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
}

struct AddFriendView_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.Name.mode = .mock
        return AddFriendView(users: [.gabby], sharedFriendId: User.gabby.id)
            .environmentObject(User.mock)
    }
}
