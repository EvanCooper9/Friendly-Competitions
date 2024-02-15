import ECKit
import Factory
import XCTest

@testable import FriendlyCompetitions

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
        XCTAssertEqual(viewModel.navigationPath, [.emailSignIn])
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

    func testMoreOptionsTapped() {
        let viewModel = WelcomeViewModel()
        XCTAssertTrue(viewModel.showMoreSignInOptionsButton)
        XCTAssertEqual(viewModel.signInOptions, [.apple])
        viewModel.moreOptionsTapped()
        XCTAssertFalse(viewModel.showMoreSignInOptionsButton)
        XCTAssertEqual(viewModel.signInOptions, [.apple, .email, .anonymous])
    }

    func testSignInOptionsID() {
        let options: [WelcomeViewModel.SignInOptions] = [.anonymous, .apple, .email]
        options.forEach { option in
            XCTAssertEqual(option.id, option.rawValue)
        }
    }
}
