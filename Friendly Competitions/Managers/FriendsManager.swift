import Combine
import Firebase
import FirebaseFirestore
import Resolver
import SwiftUI

// sourcery: AutoMockable
protocol FriendsManaging {
    var friends: AnyPublisher<[User], Never> { get }
    var friendActivitySummaries: AnyPublisher<[User.ID: ActivitySummary], Never> { get }
    var friendRequests: AnyPublisher<[User], Never> { get }

    func add(friend: User) -> AnyPublisher<Void, Error>
    func acceptFriendRequest(from: User) -> AnyPublisher<Void, Error>
    func declineFriendRequest(from: User) -> AnyPublisher<Void, Error>
    func delete(friend: User) -> AnyPublisher<Void, Error>
    func user(withId id: String) -> AnyPublisher<User?, Error>
    func search(with text: String) -> AnyPublisher<[User], Error>
}

final class FriendsManager: FriendsManaging {
    
    private struct SearchResult: Decodable {
        let name: String
    }

    // MARK: - Public Properties

    let friends: AnyPublisher<[User], Never>
    let friendActivitySummaries: AnyPublisher<[User.ID : ActivitySummary], Never>
    let friendRequests: AnyPublisher<[User], Never>

    // MARK: - Private Properties

    private let database: Firestore
    private let userManager: UserManaging

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(database: Firestore, userManager: UserManaging) {
        self.database = database
        self.userManager = userManager

        friends = userManager.user
            .flatMapAsync { user in
                try await database.collection("users")
                    .whereFieldWithChunking("id", in: user.friends)
                    .decoded(asArrayOf: User.self)
                    .sorted(by: \.name)
            }
            .ignoreFailure()

        friendRequests = userManager.user
            .flatMapAsync { user in
                try await database.collection("users")
                    .whereFieldWithChunking("id", in: user.incomingFriendRequests)
                    .decoded(asArrayOf: User.self)
            }
            .ignoreFailure()

        friendActivitySummaries = userManager.user
            .flatMapAsync { user in
                try await withThrowingTaskGroup(of: (User.ID, ActivitySummary?).self) { group -> [User.ID: ActivitySummary] in
                    let today = DateFormatter.dateDashed.string(from: .now)
                    user.friends.forEach { friendID in
                        group.addTask {
                            let activitySummary = try? await database
                                .document("users/\(friendID)/activitySummaries/\(today)")
                                .getDocument()
                                .decoded(as: ActivitySummary.self)
                            return (friendID, activitySummary)
                        }
                    }

                    var friendActivitySummaries = [User.ID: ActivitySummary]()
                    for try await (friendId, activitySummary) in group {
                        friendActivitySummaries[friendId] = activitySummary
                    }
                    return friendActivitySummaries
                }
            }
            .prepend([:])
            .ignoreFailure()
    }

    // MARK: - Public Methods

    func add(friend: User) -> AnyPublisher<Void, Error> {
        userManager.user
            .first()
            .flatMapAsync { [weak self] user in
                guard let self = self else { return }
                let batch = self.database.batch()
                if !friend.incomingFriendRequests.contains(user.id) {
                    batch.updateData(
                        ["incomingFriendRequests": friend.incomingFriendRequests.appending(user.id)],
                        forDocument: self.database.document("users" + friend.id)
                    )
                }
                if !user.incomingFriendRequests.contains(friend.id) {
                    batch.updateData(
                        ["incomingFriendRequests": user.incomingFriendRequests.appending(friend.id)],
                        forDocument: self.database.document("users" + user.id)
                    )
                }
                try await batch.commit()
            }
    }

    func acceptFriendRequest(from friendRequest: User) -> AnyPublisher<Void, Error> {
        userManager.user
            .first()
            .flatMapAsync { [weak self] user in
                guard let self = self else { return }
                let batch = self.database.batch()

                let userDocument = self.database.document("users/\(user.id)")
                let requestorDocument = self.database.document("users/\(friendRequest.id)")

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

                try await batch.commit()
            }
    }

    func declineFriendRequest(from friendRequest: User) -> AnyPublisher<Void, Error> {
        userManager.user
            .first()
            .flatMapAsync { [weak self] user in
                guard let self = self else { return }
                let batch = self.database.batch()
                let myRequests = user.incomingFriendRequests.removing(friendRequest.id)
                batch.updateData(["incomingFriendRequests": myRequests], forDocument: self.database.document("users/\(user.id)"))
                let theirRequests = friendRequest.outgoingFriendRequests.removing(user.id)
                batch.updateData(["outgoingFriendRequests": theirRequests], forDocument: self.database.document("users/\(friendRequest.id)"))
                try await batch.commit()
            }
    }

    func delete(friend: User) -> AnyPublisher<Void, Error> {
        userManager.user
            .first()
            .flatMapAsync { [weak self] user in
                guard let self = self else { return }
                let batch = self.database.batch()
                let myFriends = user.friends.removing(friend.id)
                batch.updateData(["friends": myFriends], forDocument: self.database.document("users/\(user.id)"))
                let theirFriends = friend.friends.removing(user.id)
                batch.updateData(["friends": theirFriends], forDocument: self.database.document("users/\(friend.id)"))
                try await batch.commit()
            }
    }

    func user(withId id: String) -> AnyPublisher<User?, Error> {
        .fromAsync { [weak self] in
            try await self?.database.collection("users")
                .whereField("id", isEqualTo: id)
                .getDocuments()
                .documents
                .first?
                .decoded(as: User.self)
        }
    }

    func search(with text: String) -> AnyPublisher<[User], Error> {
        .fromAsync { [weak self] in
            guard let self = self else { return [] }
            return try await self.database.collection("users")
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
    }
}
