import Combine
import CombineExt
import ECKit
import Factory
import FirebaseFirestore
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
    func user(withId id: String) -> AnyPublisher<User, Error>
}

final class FriendsManager: FriendsManaging {

    // MARK: - Public Properties

    let friends: AnyPublisher<[User], Never>
    let friendActivitySummaries: AnyPublisher<[User.ID : ActivitySummary], Never>
    let friendRequests: AnyPublisher<[User], Never>

    // MARK: - Private Properties

    @Injected(\.api) private var api
    @Injected(\.appState) private var appState
    @Injected(\.database) private var database
    @Injected(\.userManager) private var userManager
    @Injected(\.usersCache) private var usersCache
    
    let friendsSubject = ReplaySubject<[User], Never>(bufferSize: 1)
    let friendActivitySummariesSubject = ReplaySubject<[User.ID : ActivitySummary], Never>(bufferSize: 1)
    let friendRequestsSubject = ReplaySubject<[User], Never>(bufferSize: 1)

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        friends = friendsSubject.eraseToAnyPublisher()
        friendActivitySummaries = friendActivitySummariesSubject.eraseToAnyPublisher()
        friendRequests = friendRequestsSubject.eraseToAnyPublisher()
        
        appState.didBecomeActive
            .filter { $0 }
            .mapToVoid()
            .sink(withUnretained: self) { $0.listenForFriends() }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func add(user: User) -> AnyPublisher<Void, Error> {
        let data = ["userID": user.id]
        return api.call("sendFriendRequest", with: data)
    }

    func accept(friendRequest: User) -> AnyPublisher<Void, Error> {
        let data: [String: Any] = [
            "userID": friendRequest.id,
            "accept": true
        ]
        return api.call("respondToFriendRequest", with: data)
    }

    func decline(friendRequest: User) -> AnyPublisher<Void, Error> {
        let data: [String: Any] = [
            "userID": friendRequest.id,
            "accept": false
        ]
        return api.call("respondToFriendRequest", with: data)
    }

    func delete(friend: User) -> AnyPublisher<Void, Error> {
        let data = ["userID": friend.id]
        return api.call("deleteFriend", with: data)
    }

    func user(withId id: String) -> AnyPublisher<User, Error> {
        database.document("users/\(id)")
            .getDocument(as: User.self)
    }
    
    // MARK: - Private Methods
    
    private func listenForFriends() {
        userManager.userPublisher
            .map(\.friends)
            .removeDuplicates()
            .flatMapLatest(withUnretained: self) { $0.users(withIDs: $1) }
            .sink(withUnretained: self) { $0.friendsSubject.send($1) }
            .store(in: &cancellables)
        
        userManager.userPublisher
            .map(\.incomingFriendRequests)
            .removeDuplicates()
            .flatMapLatest(withUnretained: self) { $0.users(withIDs: $1) }
            .sink(withUnretained: self) { $0.friendRequestsSubject.send($1) }
            .store(in: &cancellables)

        userManager.userPublisher
            .map { $0.friends + $0.incomingFriendRequests }
            .removeDuplicates()
            .flatMapLatest(withUnretained: self) { $0.activitySummaries(for: $1) }
            .map { activitySummaries in
                let pairs = activitySummaries.compactMap { activitySummary -> (User.ID, ActivitySummary)? in
                    guard let userID = activitySummary.userID else { return nil }
                    return (userID, activitySummary)
                }
                
                return Dictionary(uniqueKeysWithValues: pairs)
            }
            .sink(withUnretained: self) { $0.friendActivitySummariesSubject.send($1) }
            .store(in: &cancellables)
    }
    
    private func users(withIDs userIDs: [User.ID]) -> AnyPublisher<[User], Never> {
        var cached = [User]()
        var toFetch = [User.ID]()
        userIDs.forEach { id in
            if let cachedUser = usersCache.users[id] {
                cached.append(cachedUser)
            } else {
                toFetch.append(id)
            }
        }
        
        return database.collection("users")
            .whereField("id", asArrayOf: User.self, in: toFetch)
            .catchErrorJustReturn([])
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf, users in
                users.forEach { strongSelf.usersCache.users[$0.id] = $0 }
            })
            .map { ($0 + cached).sorted(by: \.name) }
            .eraseToAnyPublisher()
    }
    
    private func activitySummaries(for userIDs: [User.ID]) -> AnyPublisher<[ActivitySummary], Never> {
        database.collectionGroup("activitySummaries")
            .whereField("date", isEqualTo: DateFormatter.dateDashed.string(from: .now))
            .whereField("userID", asArrayOf: ActivitySummary.self, in: userIDs)
            .catchErrorJustReturn([])
    }
}
