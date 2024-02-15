import Combine
import ECKit
import Factory
import XCTest

@testable import FriendlyCompetitions

final class FriendsManagerTests: FCTestCase {
    
    func testThatItFetchesAndUpdatesFriends() {
        let expectation = self.expectation(description: #function)
        let expected = [[], [User.andrew]]
        
        setupEmptyDatabase()
        appState.didBecomeActive = .just(true)
        
        let userPublisher = PassthroughSubject<User, Never>()
        userManager.userPublisher = userPublisher.eraseToAnyPublisher()
        
        let friendsPublisher = PassthroughSubject<[User], Error>()
        let friendsCollection = CollectionMock<User>()
        friendsCollection.whereFieldInClosure = { friendsPublisher.eraseToAnyPublisher() }
        database.collectionClosure = { collection in
            XCTAssertEqual(collection, "users")
            return friendsCollection
        }

        searchManager.searchForUsersWithIDsClosure = { ids in
            let expectedIndex = (self.searchManager.searchForUsersWithIDsCallsCount - 1) / 2
            return .just(expected[expectedIndex])
        }
        
        let manager = FriendsManager()
        manager.friends
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)
        
        userPublisher.send(.evan.with(friends: []))
        friendsPublisher.send([])
        userPublisher.send(.evan.with(friends: [User.andrew.id]))
        friendsPublisher.send([.andrew])
        
        waitForExpectations(timeout: 1)
    }
    
    func testThatItFetchesAndUpdatesFriendRequests() {
        let expectation = self.expectation(description: #function)
        let expected = [[], [User.andrew]]
        
        setupEmptyDatabase()
        appState.didBecomeActive = .just(true)
        
        let userPublisher = PassthroughSubject<User, Never>()
        userManager.userPublisher = userPublisher.eraseToAnyPublisher()
        
        let friendRequestsPublisher = PassthroughSubject<[User], Error>()
        let friendRequestsCollection = CollectionMock<User>()
        friendRequestsCollection.whereFieldInClosure = { friendRequestsPublisher.eraseToAnyPublisher() }
        database.collectionClosure = { collection in
            XCTAssertEqual(collection, "users")
            return friendRequestsCollection
        }

        searchManager.searchForUsersWithIDsClosure = { ids in
            let expectedIndex = (self.searchManager.searchForUsersWithIDsCallsCount - 1) / 2
            return .just(expected[expectedIndex])
        }
        
        let manager = FriendsManager()
        manager.friendRequests
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)
        
        userPublisher.send(.evan.with(friendRequests: []))
        friendRequestsPublisher.send([])
        userPublisher.send(.evan.with(friendRequests: [User.andrew.id]))
        friendRequestsPublisher.send([.andrew])
        
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
}
