import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class WelcomeViewModelTests: FCTestCase {

    func testThatSignInWithAppleTappedTriggersAppleSignIn() {
        authenticationManager.signInWithReturnValue = .just(())
        let viewModel = WelcomeViewModel()
        viewModel.signInWithAppleTapped()
        XCTAssertTrue(authenticationManager.signInWithCalled)
        XCTAssertEqual(authenticationManager.signInWithReceivedInvocations, [.apple])
    }

    func testThatSignInAnonymouslyTappedTriggersAnonymousSignIn() {
        let viewModel = WelcomeViewModel()
        viewModel.signInAnonymouslyTapped()
        XCTAssertTrue(viewModel.showAnonymousSignInConfirmation)
        XCTAssertFalse(authenticationManager.signInWithCalled)
    }

    func testThatConfirmAnonymousSignInTriggersAnonymousSignIn() {
        authenticationManager.signInWithReturnValue = .just(())
        let viewModel = WelcomeViewModel()
        viewModel.signInAnonymouslyTapped()
        viewModel.confirmAnonymousSignIn()
        XCTAssertTrue(authenticationManager.signInWithCalled)
        XCTAssertEqual(authenticationManager.signInWithReceivedInvocations, [.anonymous])
    }

    func testThatSignInWithEmailTappedShowsEmailSignIn() {
        let viewModel = WelcomeViewModel()
        viewModel.signInWithEmailTapped()
        XCTAssertTrue(viewModel.showEmailSignIn)
        XCTAssertFalse(authenticationManager.signInWithCalled)
    }

    func testThatSignInTriggersLoading() {
        let expectation = self.expectation(description: #function)
        let expected = [false, true, false, true, false] // false, apple, anonymous

        authenticationManager.signInWithReturnValue = .just(())

        let viewModel = WelcomeViewModel()
        viewModel.$loading
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        viewModel.signInWithAppleTapped()

        viewModel.signInAnonymouslyTapped()
        viewModel.confirmAnonymousSignIn()

        waitForExpectations(timeout: 1)
    }
}
