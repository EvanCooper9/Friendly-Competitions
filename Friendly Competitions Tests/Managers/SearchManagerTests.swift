import Combine
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class SearchManagerTests: FCTestCase {
    
    private var searchClient: SearchClientMock!
    private var userManager: UserManagingMock!
    
    private var cancellables: Cancellables!
    
    override func setUp() {
        super.setUp()
        searchClient = .init()
        userManager = .init()
        Container.shared.searchClient.register { self.searchClient }
        Container.shared.userManager.register { self.userManager }
        cancellables = .init()
    }
    
    override func tearDown() {
        super.tearDown()
        searchClient = nil
        cancellables = nil
    }
    
    func testThatSearchForCompetitionsSucceeds() {
        let expectation = self.expectation(description: #function)
        let expectedQuery = #function
        let expectedCompetitions = [Competition.mockPublic]
        
        let competitionsIndex = SearchIndexMock<Competition>()
        competitionsIndex.searchClosure = { query in
            XCTAssertEqual(query, expectedQuery)
            return .just(expectedCompetitions)
        }
        
        searchClient.indexWithNameClosure = { name in
            XCTAssertEqual(name, "competitions")
            return competitionsIndex
        }
        
        let manager = SearchManager()
        manager.searchForCompetitions(byName: expectedQuery)
            .ignoreFailure()
            .sink { competitions in
                XCTAssertEqual(competitions, expectedCompetitions)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1)
    }
    
    func testThatSearchForCompetitionsFilersPrivateCompetitions() {
        let expectation = self.expectation(description: #function)
        let expectedQuery = #function
        let expectedCompetitions = [Competition.mockPublic]
        
        let competitionsIndex = SearchIndexMock<Competition>()
        competitionsIndex.searchClosure = { query in
            XCTAssertEqual(query, expectedQuery)
            return .just(expectedCompetitions + [.mock]) // Add private compeititon that will be filtered
        }
        
        searchClient.indexWithNameClosure = { name in
            XCTAssertEqual(name, "competitions")
            return competitionsIndex
        }
        
        let manager = SearchManager()
        manager.searchForCompetitions(byName: expectedQuery)
            .ignoreFailure()
            .sink { competitions in
                XCTAssertEqual(competitions, expectedCompetitions)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1)
    }
    
    func testThatSearchForUsersSucceeds() {
        let expectation = self.expectation(description: #function)
        let expectedQuery = #function
        let expectedUsers = [User.andrew]
        
        userManager.user = User.evan
        
        let usersIndex = SearchIndexMock<User>()
        usersIndex.searchClosure = { query in
            XCTAssertEqual(query, expectedQuery)
            return .just(expectedUsers)
        }
        
        searchClient.indexWithNameClosure = { name in
            XCTAssertEqual(name, "users")
            return usersIndex
        }
        
        let manager = SearchManager()
        manager.searchForUsers(byName: expectedQuery)
            .ignoreFailure()
            .sink { users in
                XCTAssertEqual(users, expectedUsers)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1)
    }
    
    func testThatSearchForUsersFiltersOutCurrentUser() {
        let expectation = self.expectation(description: #function)
        let expectedQuery = #function
        let expectedUsers = [User.andrew]
        
        userManager.user = User.evan
        
        let usersIndex = SearchIndexMock<User>()
        usersIndex.searchClosure = { query in
            XCTAssertEqual(query, expectedQuery)
            return .just(expectedUsers + [.evan]) // Add current user that will be filtered
        }
        
        searchClient.indexWithNameClosure = { name in
            XCTAssertEqual(name, "users")
            return usersIndex
        }
        
        let manager = SearchManager()
        manager.searchForUsers(byName: expectedQuery)
            .ignoreFailure()
            .sink { users in
                XCTAssertEqual(users, expectedUsers)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1)
    }
}
