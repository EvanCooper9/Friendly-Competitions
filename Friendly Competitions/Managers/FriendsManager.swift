import Combine
import Firebase
import FirebaseFirestore
import Resolver

class AnyFriendsManager: ObservableObject {

    @Published var friends = [User]()
    @Published var friendRequests = [User]()

    func setup(with user: User) {}
    func acceptFriendRequest(from: User) {}
    func declineFriendRequest(from: User) {}
    func delete(friend: User) {}
}

final class FriendsManager: AnyFriendsManager {

    @LazyInjected private var database: Firestore

    private var user: User!
    
    // MARK: - Public Methods

    override func setup(with user: User) {
        self.user = user
        Task {
            try await updateFriends()
            try await updateFriendRequests()
        }
    }

    override func acceptFriendRequest(from friendRequest: User) {
        friends.append(friendRequest)
        friendRequests.remove(friendRequest)

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

    override func declineFriendRequest(from friendRequest: User) {
        friendRequests.remove(friendRequest)

        let batch = database.batch()
        let myRequests = user.incomingFriendRequests.removing(friendRequest.id)
        batch.updateData(["incomingFriendRequests": myRequests], forDocument: database.document("users/\(user.id)"))
        let theirRequests = friendRequest.outgoingFriendRequests.removing(user.id)
        batch.updateData(["outgoingFriendRequests": theirRequests], forDocument: database.document("users/\(friendRequest.id)"))
        batch.commit()
    }

    override func delete(friend: User) {
        friends.remove(friend)

        let batch = database.batch()
        let myFriends = user.friends.removing(friend.id)
        batch.updateData(["friends": myFriends], forDocument: database.document("users/\(user.id)"))
        let theirFriends = friend.friends.removing(user.id)
        batch.updateData(["friends": theirFriends], forDocument: database.document("users/\(friend.id)"))
        batch.commit()
    }

    // MARK: - Private Methods

    private func updateFriends() async throws {
        print(user.friends)
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

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.friends = friends
            Task { [self] in try await self.updateFriendActivitySummaries() }
        }
    }

    private func updateFriendActivitySummaries() async throws {
        try await withThrowingTaskGroup(of: (User, ActivitySummary?).self) { group in
            friends.forEach { friend in
                group.addTask { [weak self] in
                    let activitySummary = try await self?.database
                        .collection("users/\(friend.id)/activitySummaries")
                        .whereField("date", isEqualTo: DateFormatter.dateDashed.string(from: .now))
                        .getDocuments()
                        .documents
                        .first?
                        .decoded(as: ActivitySummary.self)
                    return (friend, activitySummary)
                }
            }

            var friends = [User]()
            for try await (friend, activitySummary) in group {
                friend.tempActivitySummary = activitySummary
                friends.append(friend)
            }
            DispatchQueue.main.async { [weak self, friends] in
                self?.friends = friends
            }
        }
    }

    private func updateFriendRequests() async throws {
        guard !user.incomingFriendRequests.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.friendRequests = []
            }
            return
        }

        let friendRequests = try await database.collection("users")
            .whereField("id", in: user.incomingFriendRequests)
            .getDocuments()
            .documents
            .decoded(asArrayOf: User.self)

        DispatchQueue.main.async { [weak self] in
            self?.friendRequests = friendRequests
        }
    }
}
