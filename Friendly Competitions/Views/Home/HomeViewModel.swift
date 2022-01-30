import Combine
import Firebase
import FirebaseFirestore
import HealthKit
import Resolver

final class HomeViewModel: ObservableObject {

    @Published private(set) var activitySummary: HKActivitySummary?
    @Published private(set) var friends = [User]()
    @Published private(set) var friendRequests = [User]()
    @Published var shouldPresentPermissions = false

    @LazyInjected private var database: Firestore
    @LazyInjected var user: User

    init() {
//        let health = healthKitManager.permissionStatus == .notDetermined
//        let contacts = contactsManager.permissionStatus == .notDetermined
//        notificationManager.permissionStatus { [weak self] notifications in
//            DispatchQueue.main.async {
//                self?.shouldPresentPermissions = health || contacts || (notifications == .notDetermined)
//            }
//        }
    }

    // MARK: - Public Methods

    func accept(_ friendRequest: User) {
        let batch = database.batch()

        let userDocument = database.document("users/\(user.id)")
        let myRequests = user.incomingFriendRequests.removing(friendRequest.id)
        let myFriends = user.friends.appending(friendRequest.id)
        batch.updateData(["incomingFriendRequests": myRequests], forDocument: userDocument)
        batch.updateData(["friends": myFriends], forDocument: userDocument)

        let requestorDocument = database.document("users/\(friendRequest.id)")
        let theirRequests = friendRequest.outgoingFriendRequests.removing(user.id)
        let theirFriends = friendRequest.friends.appending(user.id)
        batch.updateData(["outgoingFriendRequests": theirRequests], forDocument: requestorDocument)
        batch.updateData(["friends": theirFriends], forDocument: requestorDocument)

        batch.commit()
    }

    func decline(_ friendRequest: User) {
        let batch = database.batch()

        let myRequests = user.incomingFriendRequests.removing(friendRequest.id)
        batch.updateData(["incomingFriendRequests": myRequests], forDocument: database.document("users/\(user.id)"))

        let theirRequests = friendRequest.outgoingFriendRequests.removing(user.id)
        batch.updateData(["outgoingFriendRequests": theirRequests], forDocument: database.document("users/\(friendRequest.id)"))

        batch.commit()
    }

    func delete(friendsAtIndex indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let friend = friends[index]

        let batch = database.batch()

        let myFriends = user.friends.removing(friend.id)
        batch.updateData(["friends": myFriends], forDocument: database.document("users/\(user.id)"))

        let theirFriends = friend.friends.removing(user.id)
        batch.updateData(["friends": theirFriends], forDocument: database.document("users/\(friend.id)"))

        batch.commit()
    }

    // MARK: - Private Methods

    private func updateFriends() async throws {
        guard !user.friends.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.friends = []
            }
            return
        }

        let friends = try await database.collection("users")
            .whereField("id", in: user.friends)
            .getDocuments()
            .documents
            .decoded(asArrayOf: User.self)

        for (index, friend) in friends.enumerated() {
            friends[index].tempActivitySummary = try await database
                .collection("users/\(friend.id)/activitySummaries")
                .whereField("date", isEqualTo: DateFormatter.dateDashed.string(from: .now))
                .getDocuments()
                .documents
                .first?
                .decoded(as: ActivitySummary.self)
        }

        DispatchQueue.main.async { [weak self] in
            self?.friends = friends
        }
    }

    private func updateFriendRequests() async throws {
        guard !user.incomingFriendRequests.isEmpty else {
            DispatchQueue.main.async {
                self.friendRequests = []
            }
            return
        }

        let friendRequests = try await database.collection("users")
            .whereField("id", in: user.incomingFriendRequests)
            .getDocuments()
            .documents
            .decoded(asArrayOf: User.self)

        DispatchQueue.main.async {
            self.friendRequests = friendRequests
        }
    }
}

