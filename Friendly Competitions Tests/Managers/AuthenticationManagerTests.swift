import CombineSchedulers
import ECKit
import XCTest

@testable import Friendly_Competitions

final class AuthenticationManagerTests: FCTestCase {

    private var auth: AuthProvidingMock!
    private var authenticationCache: AuthenticationCacheMock!
    private var database: DatabaseMock!
    private var scheduler: TestSchedulerOf<RunLoop>!
    private var signInWithAppleProvider: SignInWithAppleProvidingMock!

    private var cancellables: Cancellables!

    override func setUp() {
        super.setUp()

        auth = .init()
        authenticationCache = .init()
        database = .init()
        scheduler = .init(now: .init(.now))
        signInWithAppleProvider = .init()

        container.auth.register { self.auth }
        container.authenticationCache.register { self.authenticationCache }
        container.database.register { self.database }
        container.scheduler.register { self.scheduler.eraseToAnyScheduler() }
        container.signInWithAppleProvider.register { self.signInWithAppleProvider }

        cancellables = .init()
    }

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
