import Combine
import ECKit
import Factory
import XCTest

@testable import FriendlyCompetitions

final class SearchManagerTests: FCTestCase {
    
    override func setUp() {
        super.setUp()

        environmentManager.environment = .prod
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
