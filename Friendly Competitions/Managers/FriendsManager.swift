import Combine
import Firebase
import FirebaseFirestore
import Resolver
import SwiftUI

class AnyFriendsManager: ObservableObject {

    @Published(storedWithKey: .friends) var friends = [User]()
    @Published(storedWithKey: .friendActivitySummaries) var friendActivitySummaries = [User.ID: ActivitySummary]()
    @Published var friendRequests = [User]()

    func add(friend: User) {}
    func acceptFriendRequest(from: User) {}
    func declineFriendRequest(from: User) {}
    func delete(friend: User) {}
    func user(withId id: String) async throws -> User? { nil }
    func search(with text: String) async throws -> [User] { [] }
}

final class FriendsManager: AnyFriendsManager {
    
    private struct SearchResult: Decodable {
        let name: String
    }

    // MARK: - Private Properties

    @Injected private var database: Firestore
    @InjectedObject private var userManager: AnyUserManager

    private var searchTask: Task<Void, Error>? {
        willSet { searchTask?.cancel() }
    }

    private var user: User { userManager.user }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override init() {
        super.init()
        queueUpdates()

        userManager.$user
            .sink { [weak self] _ in self?.queueUpdates() }
            .store(in: &cancellables)
    }
    
    deinit {
        friends.removeAll()
        friendActivitySummaries.removeAll()
    }

    // MARK: - Public Methods

    override func add(friend: User) {
        if !userManager.user.outgoingFriendRequests.contains(friend.id) {
            userManager.user.outgoingFriendRequests.append(friend.id)
        }

        if !friend.incomingFriendRequests.contains(user.id) {
            database.document("users/\(friend.id)").updateData(["incomingFriendRequests": friend.incomingFriendRequests.appending(user.id)])
        }
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

    override func user(withId id: String) async throws -> User? {
        try await database.collection("users")
            .whereField("id", isEqualTo: id)
            .getDocuments()
            .documents
            .first?
            .decoded(as: User.self)
    }
    
    override func search(with text: String) async throws -> [User] {
        guard !text.isEmpty else { return [] }
        return try await database.collection("users")
            .whereField("searchable", isEqualTo: true)
            .getDocuments()
            .documents
            .decoded(asArrayOf: User.self)
            .filter { someUser in
                someUser.name
                    .lowercased()
                    .split(separator: " ")
                    .contains { $0.starts(with: text.lowercased()) }
            }
            .sorted(by: \.name)
    }

    // MARK: - Private Methods

    private func queueUpdates() {
        Task {
            try await updateFriends()
            try await updateFriendRequests()
            try await updateFriendActivitySummaries()
        }
    }

    private func updateFriends() async throws {
        guard !user.friends.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.friends = []
            }
            return
        }

        let friends = try await self.database.collection("users")
            .whereFieldWithChunking("id", in: user.friends)
            .decoded(asArrayOf: User.self)
            .sorted(by: \.name)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.friends = friends
            Task { [self] in try await self.updateFriendActivitySummaries() }
        }
    }

    private func updateFriendActivitySummaries() async throws {
        try await withThrowingTaskGroup(of: (User.ID, ActivitySummary?).self) { group in
            friends.forEach { friend in
                group.addTask { [weak self] in
                    // TODO: use whereIn("date", is: DateFormatter.dateDashed.string(from: .now)) filter when most users have installed >= 1.1.0
                    let activitySummary = try await self?.database
                        .collection("users/\(friend.id)/activitySummaries")
                        .getDocuments()
                        .documents
                        .last?
                        .decoded(as: ActivitySummary.self)
                    let now = DateFormatter.dateDashed.string(from: .now)
                    let isFromToday = activitySummary?.date.encodedToString().starts(with: now) == true
                    return (friend.id, isFromToday ? activitySummary : nil)
                }
            }

            var friendActivitySummaries = [User.ID: ActivitySummary]()
            for try await (friendId, activitySummary) in group {
                friendActivitySummaries[friendId] = activitySummary
            }
            DispatchQueue.main.async { [weak self, friendActivitySummaries] in
                self?.friendActivitySummaries = friendActivitySummaries
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
            .whereFieldWithChunking("id", in: user.incomingFriendRequests)
            .decoded(asArrayOf: User.self)

        DispatchQueue.main.async { [weak self] in
            self?.friendRequests = friendRequests
        }
    }
}
