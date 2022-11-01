import Combine
import CombineExt
import ECKit
import ECKit_Firebase
import Factory
import Firebase
import FirebaseFirestoreCombineSwift
import FirebaseFunctionsCombineSwift
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

    var friends: AnyPublisher<[User], Never> { friendsSubject.share(replay: 1).eraseToAnyPublisher() }
    var friendActivitySummaries: AnyPublisher<[User.ID : ActivitySummary], Never> { friendActivitySummariesSubject.share(replay: 1).eraseToAnyPublisher() }
    var friendRequests: AnyPublisher<[User], Never> { friendRequestsSubject.share(replay: 1).eraseToAnyPublisher() }

    // MARK: - Private Properties

    @Injected(Container.database) private var database
    @Injected(Container.functions) private var functions
    @Injected(Container.userManager) private var userManager
    
    let friendsSubject = PassthroughSubject<[User], Never>()
    let friendActivitySummariesSubject = PassthroughSubject<[User.ID : ActivitySummary], Never>()
    let friendRequestsSubject = PassthroughSubject<[User], Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        let allFriends = userManager.user
            .flatMapAsync { [weak self] user -> [User] in
                guard let strongSelf = self else { return [] }                
                return try await strongSelf.database.collection("users")
                    .whereFieldWithChunking("id", in: user.friends + user.incomingFriendRequests)
                    .decoded(asArrayOf: User.self)
                    .sorted(by: \.name)
            }
            .share(replay: 1)
            .ignoreFailure()

        Publishers
            .CombineLatest(userManager.user, allFriends)
            .map { user, allFriends in
                allFriends.filter { user.friends.contains($0.id) }
            }
            .print("friends")
            .sink(withUnretained: self) { $0.friendsSubject.send($1) }
            .store(in: &cancellables)

        Publishers
            .CombineLatest(userManager.user, allFriends)
            .map { user, allFriends in
                allFriends.filter { user.incomingFriendRequests.contains($0.id) }
            }
            .print("friend requests")
            .sink(withUnretained: self) { $0.friendRequestsSubject.send($1) }
            .store(in: &cancellables)

        allFriends
            .flatMapAsync { [weak self] (friends: [User]) in
                guard let strongSelf = self else { return [:] }
                
                let activitySummaries = try await strongSelf.database.collectionGroup("activitySummaries")
                    .whereField("date", isEqualTo: DateFormatter.dateDashed.string(from: .now))
                    .whereFieldWithChunking("userID", in: friends.map(\.id))
                    .decoded(asArrayOf: ActivitySummary.self)
                
                let pairs = activitySummaries.compactMap { activitySummary -> (User.ID, ActivitySummary)? in
                    guard let userID = activitySummary.userID else { return nil }
                    return (userID, activitySummary)
                }
                
                return Dictionary(uniqueKeysWithValues: pairs)
            }
            .sink(withUnretained: self) { $0.friendActivitySummariesSubject.send($1) }
            .store(in: &cancellables)
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
