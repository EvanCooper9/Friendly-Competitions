import Combine
import Firebase
import FirebaseFirestore
import Resolver
import SwiftUI

class AnyFriendsManager: ObservableObject {

    @Published(storedWithKey: "friends") var friends = [User]()
    @Published var friendRequests = [User]()
    @Published var searchResults = [User]()
    @Published var searchText = ""

    func setup(with user: User) {}
    func add(friend: User) {}
    func acceptFriendRequest(from: User) {}
    func declineFriendRequest(from: User) {}
    func delete(friend: User) {}
}

final class FriendsManager: AnyFriendsManager {

    // MARK: - Public Properties

    override var searchText: String {
        didSet {
            guard !searchText.isEmpty else {
                searchResults.removeAll()
                return
            }
            searchTask = Task { try await searchUsers() }
        }
    }

    // MARK: - Private Properties

    @LazyInjected private var database: Firestore

    private var user: User!

    private var searchTask: Task<Void, Error>? {
        willSet { searchTask?.cancel() }
    }

    // MARK: - Public Methods

    override func setup(with user: User) {
        self.user = user
        Task {
            try await updateFriends()
            try await updateFriendRequests()
        }
    }

    override func add(friend: User) {
        user.outgoingFriendRequests.append(friend.id)

        let batch = database.batch()

        if !user.outgoingFriendRequests.contains(friend.id) {
            let outgoingFriendRequests = user.outgoingFriendRequests.appending(friend.id)
            batch.updateData(["outgoingFriendRequests": outgoingFriendRequests], forDocument: database.document("users/\(user.id)"))
        }

        if !friend.incomingFriendRequests.contains(user.id) {
            let incomingFriendRequests = friend.incomingFriendRequests.appending(user.id)
            batch.updateData(["incomingFriendRequests": incomingFriendRequests], forDocument: database.document("users/\(friend.id)"))
        }

        batch.commit()
    }

    override func acceptFriendRequest(from friendRequest: User) {
        friends.append(friendRequest)
        friendRequests.remove(friendRequest)

        let batch = database.batch()
        let userDocument = database.document("users/\(user.id)")
        let requestorDocument = database.document("users/\(friendRequest.id)")

        if user.incomingFriendRequests.contains(friendRequest.id) {
            let myRequests = user.incomingFriendRequests.removing(friendRequest.id)
            batch.updateData(["incomingFriendRequests": myRequests], forDocument: userDocument)
        }

        if !user.friends.contains(friendRequest.id) {
            let myFriends = user.friends.appending(friendRequest.id)
            batch.updateData(["friends": myFriends], forDocument: userDocument)
        }

        if friendRequest.outgoingFriendRequests.contains(user.id) {
            let theirRequests = friendRequest.outgoingFriendRequests.removing(user.id)
            batch.updateData(["outgoingFriendRequests": theirRequests], forDocument: requestorDocument)
        }

        if !friendRequest.friends.contains(user.id) {
            let theirFriends = friendRequest.friends.appending(user.id)
            batch.updateData(["friends": theirFriends], forDocument: requestorDocument)
        }

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
            .sorted(by: \.name.first!)

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
                    // TODO: use whereIn filter on firestore collection when most users have installed >= 1.1.0
                    let activitySummary = try await self?.database
                        .collection("users/\(friend.id)/activitySummaries")
                        .getDocuments()
                        .documents
                        .decoded(asArrayOf: ActivitySummary.self)
                        .first { $0.date.encodedToString().starts(with: DateFormatter.dateDashed.string(from: .now)) }
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

    private func searchUsers() async throws {
        let users = try await database.collection("users")
            .getDocuments()
            .documents
            .decoded(asArrayOf: User.self)
            .filter { someUser in
                guard someUser.name.lowercased().contains(searchText.lowercased()) else { return false }
                return !user.friends
                    .appending(user.id)
                    .contains { $0 == someUser.id }
            }
            .sorted(by: \.name)

        try Task.checkCancellation()

        DispatchQueue.main.async { [weak self] in
            self?.searchResults = users
        }
    }
}
