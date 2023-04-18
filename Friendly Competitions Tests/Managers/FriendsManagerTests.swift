import Combine
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class FriendsManagerTests: FCTestCase {
    
    private var api: APIMock!
    private var appState: AppStateProvidingMock!
    private var database: DatabaseMock!
    private var searchManager: SearchManagingMock!
    private var userManager: UserManagingMock!
    
    private var cancellables: Cancellables!
    
    override func setUp() {
        super.setUp()
        
        api = .init()
        appState = .init()
        database = .init()
        searchManager = .init()
        userManager = .init()
        
        container.api.register { self.api }
        container.appState.register { self.appState }
        container.searchManager.register { self.searchManager }
        container.database.register { self.database }
        container.userManager.register { self.userManager }
        
        cancellables = .init()
    }
    
    func testThatItFetchesAndUpdatesFriends() {
        let expectation = self.expectation(description: #function)
        let expected: [[User]] = [[], [.andrew]]
        
        setupEmptyDatabase()
        appState.didBecomeActive = .just(true)
        
        let userPublisher = PassthroughSubject<User, Never>()
        userManager.userPublisher = userPublisher.eraseToAnyPublisher()

        searchManager.searchForUsersWithIDsClosure = { ids in
            // count needs to be /2 because it is called twice (friends and friend requests)
            let count = (self.searchManager.searchForUsersWithIDsCallsCount - 1) / 2

            return .just(expected[count])
        }

        let friendsPublisher = PassthroughSubject<[User], Error>()
        let friendsCollection = CollectionMock<User>()
        friendsCollection.whereFieldInClosure = { friendsPublisher.eraseToAnyPublisher() }
        database.collectionClosure = { collection in
            XCTAssertEqual(collection, "users")
            return friendsCollection
        }
        
        let manager = FriendsManager()
        manager.friends
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        expected.forEach { friends in
            userPublisher.send(.evan.with(friends: friends.map(\.id)))
            friendsPublisher.send(friends)
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testThatItFetchesAndUpdatesFriendRequests() {
        let expectation = self.expectation(description: #function)
        let expected: [[User]] = [[], [.andrew]]
        
        setupEmptyDatabase()
        appState.didBecomeActive = .just(true)
        
        let userPublisher = PassthroughSubject<User, Never>()
        userManager.userPublisher = userPublisher.eraseToAnyPublisher()

        searchManager.searchForUsersWithIDsClosure = { ids in
            // count needs to be /2 because it is called twice (friends and friend requests)
            let count = (self.searchManager.searchForUsersWithIDsCallsCount - 1) / 2

            return .just(expected[count])
        }
        
        let friendRequestsPublisher = PassthroughSubject<[User], Error>()
        let friendRequestsCollection = CollectionMock<User>()
        friendRequestsCollection.whereFieldInClosure = { friendRequestsPublisher.eraseToAnyPublisher() }
        database.collectionClosure = { collection in
            XCTAssertEqual(collection, "users")
            return friendRequestsCollection
        }
        
        let manager = FriendsManager()
        manager.friendRequests
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)
        
        expected.forEach { friends in
            userPublisher.send(.evan.with(friendRequests: friends.map(\.id)))
            friendRequestsPublisher.send(friends)
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testThatItDoesNotFetchFriendsUnlessActive() {
        appState.didBecomeActive = .never()
        
        let collection = CollectionMock<User>()
        database.collectionClosure = { _ in
            XCTFail("Should not be called")
            return collection
        }
        
        let manager = FriendsManager()
        manager.friends
            .sink()
            .store(in: &cancellables)
    }
    
    func testThatAddSucceeds() {
        let expectaion = self.expectation(description: #function)
        appState.didBecomeActive = .never()
        api.callWithReturnValue = .just(())
        
        let manager = FriendsManager()
        let user = User.evan
        testAPI(manager.add(user: user), expect: .success(()), expectation: expectaion)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "sendFriendRequest")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["userID"] as? String, user.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 1)
        waitForExpectations(timeout: 1)
    }
    
    func testThatAddFails() {
        let expectation = self.expectation(description: #function)
        let error = MockError.mock(id: #function)
        api.callWithReturnValue = .error(error)
        appState.didBecomeActive = .never()
        
        let user = User.evan
        let manager = FriendsManager()
        
        testAPI(manager.add(user: user), expect: .failure(error), expectation: expectation)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "sendFriendRequest")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["userID"] as? String, user.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 1)
        waitForExpectations(timeout: 1)
    }
    
    func testThatAcceptSucceeds() {
        let expectaion = self.expectation(description: #function)
        appState.didBecomeActive = .never()
        api.callWithReturnValue = .just(())
        let manager = FriendsManager()
        let user = User.evan
        testAPI(manager.accept(friendRequest: user), expect: .success(()), expectation: expectaion)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "respondToFriendRequest")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["userID"] as? String, user.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?["accept"] as? Bool, true)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 2)
        waitForExpectations(timeout: 1)
    }
    
    func testThatAcceptFails() {
        let expectaion = self.expectation(description: #function)
        let error = MockError.mock(id: #function)
        api.callWithReturnValue = .error(error)
        appState.didBecomeActive = .never()
        
        let manager = FriendsManager()
        let user = User.evan
        testAPI(manager.accept(friendRequest: user), expect: .failure(error), expectation: expectaion)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "respondToFriendRequest")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["userID"] as? String, user.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?["accept"] as? Bool, true)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 2)
        waitForExpectations(timeout: 1)
    }
    
    func testThatDeclineSucceeds() {
        let expectaion = self.expectation(description: #function)
        appState.didBecomeActive = .never()
        api.callWithReturnValue = .just(())
        let manager = FriendsManager()
        let user = User.evan
        testAPI(manager.decline(friendRequest: user), expect: .success(()), expectation: expectaion)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "respondToFriendRequest")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["userID"] as? String, user.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?["accept"] as? Bool, false)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 2)
        waitForExpectations(timeout: 1)
    }
    
    func testThatDeclineFails() {
        let expectaion = self.expectation(description: #function)
        let error = MockError.mock(id: #function)
        api.callWithReturnValue = .error(error)
        appState.didBecomeActive = .never()
        
        let manager = FriendsManager()
        let user = User.evan
        testAPI(manager.decline(friendRequest: user), expect: .failure(error), expectation: expectaion)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "respondToFriendRequest")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["userID"] as? String, user.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?["accept"] as? Bool, false)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 2)
        waitForExpectations(timeout: 1)
    }
    
    func testThatDeleteSucceeds() {
        let expectaion = self.expectation(description: #function)
        appState.didBecomeActive = .never()
        api.callWithReturnValue = .just(())
        let manager = FriendsManager()
        let user = User.evan
        testAPI(manager.delete(friend: user), expect: .success(()), expectation: expectaion)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "deleteFriend")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["userID"] as? String, user.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 1)
        waitForExpectations(timeout: 1)
    }
    
    func testThatDeleteFails() {
        let expectaion = self.expectation(description: #function)
        let error = MockError.mock(id: #function)
        api.callWithReturnValue = .error(error)
        appState.didBecomeActive = .never()
        
        let manager = FriendsManager()
        let user = User.evan
        testAPI(manager.delete(friend: user), expect: .failure(error), expectation: expectaion)
        
        XCTAssertEqual(api.callWithCallsCount, 1)
        XCTAssertEqual(api.callWithReceivedArguments?.endpoint, "deleteFriend")
        XCTAssertEqual(api.callWithReceivedArguments?.data?["userID"] as? String, user.id)
        XCTAssertEqual(api.callWithReceivedArguments?.data?.count, 1)
        waitForExpectations(timeout: 1)
    }
    
    // MARK: - Private
    
    private func setupEmptyDatabase() {
        let usersCollection = CollectionMock<User>()
        usersCollection.whereFieldInClosure = { .just([]) }
        database.collectionReturnValue = usersCollection
        
        let activitySummariesCollection = CollectionMock<ActivitySummary>()
        activitySummariesCollection.whereFieldIsEqualToClosure = { activitySummariesCollection }
        activitySummariesCollection.whereFieldInClosure = { .just([]) }
        database.collectionGroupReturnValue = activitySummariesCollection
    }
    
    private func testAPI(_ publisher: AnyPublisher<Void, Error>, expect expectedResult: Result<Void, MockError>, expectation: XCTestExpectation) {
        publisher
            .mapToResult()
            .sink { result in
                switch (result, expectedResult) {
                case (.success, .success):
                    expectation.fulfill()
                case (.failure(let error), .failure(let expectedError)):
                    guard let error = error as? MockError else {
                        XCTFail("Wrong error type")
                        return
                    }
                    XCTAssertEqual(error, expectedError)
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
