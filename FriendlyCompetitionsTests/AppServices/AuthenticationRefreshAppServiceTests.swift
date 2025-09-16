import Combine
import FCKit
import XCTest

@testable import FriendlyCompetitions

final class AuthenticationRefreshAppServiceTests: FCTestCase {

    func testThatReauthenticationIsTriggeredOnBackgroundNotification() {
        let expectation = self.expectation(description: #function)

        // Setup mocks
        authenticationManager.shouldReauthenticateReturnValue = .just(true)
        authenticationManager.reauthenticateReturnValue = .just(())

        let service = AuthenticationRefreshAppService()

        // Simulate background notification
        service.didReceiveRemoteNotification(with: [:])
            .sink {
                XCTAssertTrue(self.analyticsManager.logEventCalled)
                XCTAssertTrue(self.authenticationManager.shouldReauthenticateCalled)
                XCTAssertTrue(self.authenticationManager.reauthenticateCalled)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testThatReauthenticationIsSkippedWhenNotNeeded() {
        let expectation = self.expectation(description: #function)

        // Setup mocks
        authenticationManager.shouldReauthenticateReturnValue = .just(false)
        authenticationManager.reauthenticateReturnValue = .just(())

        let service = AuthenticationRefreshAppService()

        // Simulate background notification
        service.didReceiveRemoteNotification(with: [:])
            .sink {
                XCTAssertTrue(self.analyticsManager.logEventCalled)
                XCTAssertTrue(self.authenticationManager.shouldReauthenticateCalled)
                XCTAssertFalse(self.authenticationManager.reauthenticateCalled)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testThatReauthenticationHandlesErrors() {
        let expectation = self.expectation(description: #function)

        // Setup mocks with error
        authenticationManager.shouldReauthenticateReturnValue = .error(MockError.mock(id: #function))
        authenticationManager.reauthenticateReturnValue = .just(())

        let service = AuthenticationRefreshAppService()

        // Simulate background notification
        service.didReceiveRemoteNotification(with: [:])
            .sink {
                XCTAssertTrue(self.analyticsManager.logEventCalled)
                XCTAssertTrue(self.authenticationManager.shouldReauthenticateCalled)
                XCTAssertFalse(self.authenticationManager.reauthenticateCalled)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }
}