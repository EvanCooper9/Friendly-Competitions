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

    @Injected(Container.api) private var api
    @Injected(Container.appState) private var appState
    @Injected(Container.database) private var database
    @Injected(Container.userManager) private var userManager
    
    let friendsSubject = CurrentValueSubject<[User], Never>([])
    let friendActivitySummariesSubject = CurrentValueSubject<[User.ID : ActivitySummary], Never>([:])
    let friendRequestsSubject = CurrentValueSubject<[User], Never>([])

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
        let allFriends = userManager.userPublisher
            .flatMapLatest(withUnretained: self) { strongSelf, user in
                strongSelf.database.collection("users")
                    .whereField("id", asArrayOf: User.self, in: user.friends + user.incomingFriendRequests)
                    .map { $0.sorted(by: \.name) }
                    .catchErrorJustReturn([])
            }
            .share(replay: 1)

        Publishers
            .CombineLatest(userManager.userPublisher, allFriends)
            .map { user, allFriends in
                allFriends.filter { user.friends.contains($0.id) }
            }
            .sink(withUnretained: self) { $0.friendsSubject.send($1) }
            .store(in: &cancellables)

        Publishers
            .CombineLatest(userManager.userPublisher, allFriends)
            .map { user, allFriends in
                allFriends.filter { user.incomingFriendRequests.contains($0.id) }
            }
            .sink(withUnretained: self) { $0.friendRequestsSubject.send($1) }
            .store(in: &cancellables)

        allFriends
            .flatMapLatest(withUnretained: self) { strongSelf, friends in
                strongSelf.database.collectionGroup("activitySummaries")
                    .whereField("date", isEqualTo: DateFormatter.dateDashed.string(from: .now))
                    .whereField("userID", asArrayOf: ActivitySummary.self, in: friends.map(\.id))
                    .catchErrorJustReturn([])
            }
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
}
