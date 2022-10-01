import Combine
import CombineExt
import ECKit
import ECKit_Firebase
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import FirebaseFunctionsCombineSwift
import Resolver
import SwiftUI

// sourcery: AutoMockable
protocol FriendsManaging {
    var friends: AnyPublisher<[User], Never> { get }
    var friendActivitySummaries: AnyPublisher<[User.ID: ActivitySummary], Never> { get }
    var friendRequests: AnyPublisher<[User], Never> { get }

    func add(user: User) -> AnyPublisher<Void, Error>
    func accept(friendRequest: User) -> AnyPublisher<Void, Error>
    func decline(friendRequest: User) -> AnyPublisher<Void, Error>
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
    private let functions: Functions
    private let userManager: UserManaging

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(database: Firestore, functions: Functions, userManager: UserManaging) {
        self.database = database
        self.functions = functions
        self.userManager = userManager

        let allFriends = userManager.user
            .flatMapAsync { user in
                try await database.collection("users")
                    .whereFieldWithChunking("id", in: user.friends + user.incomingFriendRequests)
                    .decoded(asArrayOf: User.self)
                    .sorted(by: \.name)
            }
            .ignoreFailure()

        friends = Publishers
            .CombineLatest(userManager.user, allFriends)
            .map { user, allFriends in
                allFriends.filter { user.friends.contains($0.id) }
            }
            .share(replay: 1)
            .eraseToAnyPublisher()

        friendRequests = Publishers
            .CombineLatest(userManager.user, allFriends)
            .map { user, allFriends in
                allFriends.filter { user.incomingFriendRequests.contains($0.id) }
            }
            .share(replay: 1)
            .eraseToAnyPublisher()

        friendActivitySummaries = allFriends
            .flatMapAsync { friends in
                try await withThrowingTaskGroup(of: (User.ID, ActivitySummary?).self) { group -> [User.ID: ActivitySummary] in
                    let today = DateFormatter.dateDashed.string(from: .now)
                    friends.forEach { friend in
                        group.addTask {
                            let activitySummary = try? await database
                                .document("users/\(friend.id)/activitySummaries/\(today)")
                                .getDocument()
                                .decoded(as: ActivitySummary.self)
                            return (friend.id, activitySummary)
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
            .share(replay: 1)
            .ignoreFailure()
    }

    // MARK: - Public Methods

    func add(user: User) -> AnyPublisher<Void, Error> {
        functions.httpsCallable("sendFriendRequest")
            .call(["userID": user.id])
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func accept(friendRequest: User) -> AnyPublisher<Void, Error> {
        functions.httpsCallable("respondToFriendRequest")
            .call([
                "userID": friendRequest.id,
                "accept": true
            ])
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func decline(friendRequest: User) -> AnyPublisher<Void, Error> {
        functions.httpsCallable("respondToFriendRequest")
            .call([
                "userID": friendRequest.id,
                "accept": false
            ])
            .print()
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func delete(friend: User) -> AnyPublisher<Void, Error> {
        functions.httpsCallable("deleteFriend")
            .call(["userID": friend.id])
            .mapToVoid()
            .eraseToAnyPublisher()
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
        userManager.user
            .map(\.id)
            .setFailureType(to: Error.self)
            .flatMapAsync { [weak self] currentUserID in
                guard let self = self else { return [] }
                return try await self.database.collection("users")
                    .whereField("id", isNotEqualTo: currentUserID)
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
