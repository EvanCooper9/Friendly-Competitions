import Combine
import CombineExt
import ECKit
import ECKit_Firebase
import Factory
import FirebaseFirestore
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
}

final class FriendsManager: FriendsManaging {

    // MARK: - Public Properties

    let friends: AnyPublisher<[User], Never>
    let friendActivitySummaries: AnyPublisher<[User.ID : ActivitySummary], Never>
    let friendRequests: AnyPublisher<[User], Never>

    // MARK: - Private Properties

    @Injected(Container.appState) private var appState
    @Injected(Container.database) private var database
    @Injected(Container.functions) private var functions
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
        database.document("users/\(id)")
            .getDocument()
            .map { try? $0.data(as: User.self) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func listenForFriends() {
        let allFriends = userManager.userPublisher
            .flatMapAsync { [weak self] user -> [User] in
                guard let strongSelf = self else { return [] }
                return try await strongSelf.database.collection("users")
                    .whereFieldWithChunking("id", in: user.friends + user.incomingFriendRequests)
                    .decoded(asArrayOf: User.self)
                    .sorted(by: \.name)
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
}
