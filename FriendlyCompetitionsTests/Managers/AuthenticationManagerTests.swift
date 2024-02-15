import CombineSchedulers
import ECKit
import XCTest

@testable import FriendlyCompetitions

final class AuthenticationManagerTests: FCTestCase {

    func testThatLoggedInIsFalseOnLaunch() {
        let expectation = self.expectation(description: #function)

        auth.userPublisherReturnValue = .never()

        let manager = AuthenticationManager()
        manager.loggedIn
            .expect(false, expectation: expectation)
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testThatIsLoggedInIsTrueOnLaunch() {
        let expectation = self.expectation(description: #function)

        auth.userPublisherReturnValue = .never()
        authenticationCache.currentUser = .evan

        let manager = AuthenticationManager()
        manager.loggedIn
            .expect(true, expectation: expectation)
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }
}
