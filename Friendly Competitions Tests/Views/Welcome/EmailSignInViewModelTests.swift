import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class EmailSignInViewModelTests: FCTestCase {

    private var authenticationManager: AuthenticationManagingMock!
    private var cancellables: Cancellables!

    override func setUp() {
        super.setUp()

        authenticationManager = .init()
        cancellables = .init()

        container.authenticationManager.register { self.authenticationManager }
    }

    func testThatInputTypeIsToggled() {
        let viewModel = EmailSignInViewModel()
        XCTAssertEqual(viewModel.inputType, .signIn)
        viewModel.signUpTapped()
        XCTAssertEqual(viewModel.inputType, .signUp)
        viewModel.signInTapped()
        XCTAssertEqual(viewModel.inputType, .signIn)
    }

    func testThatSignInTriggersLoading() {
        let expectation = self.expectation(description: #function)
        let expected = [false, true, false]

        authenticationManager.signInWithReturnValue = .just(())

        let viewModel = EmailSignInViewModel()
        viewModel.$loading
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        viewModel.continueTapped()

        waitForExpectations(timeout: 1)
    }

    func testThatSignInErrorIsPresented() {
        let expectedError = MockError.mock(id: #function)

        authenticationManager.signInWithReturnValue = .error(expectedError)

        let viewModel = EmailSignInViewModel()
        viewModel.continueTapped()

        XCTAssertEqual(viewModel.error as? MockError, expectedError)
    }

    func testThatSignUpErrorIsPresented() {
        let expectedError = MockError.mock(id: #function)

        authenticationManager.signUpNameEmailPasswordPasswordConfirmationReturnValue = .error(expectedError)

        let viewModel = EmailSignInViewModel()
        viewModel.signUpTapped()
        viewModel.continueTapped()

        XCTAssertEqual(viewModel.error as? MockError, expectedError)
    }

    func testThatForgotTriggersPasswordReset() {
        let expectedEmail = #function

        authenticationManager.sendPasswordResetToReturnValue = .just(())

        let viewModel = EmailSignInViewModel()
        viewModel.email = expectedEmail
        viewModel.forgotTapped()
        XCTAssertTrue(authenticationManager.sendPasswordResetToCalled)
        XCTAssertEqual(authenticationManager.sendPasswordResetToReceivedInvocations, [expectedEmail])
    }

    func testThatForgotTriggersLoading() {
        let expectation = self.expectation(description: #function)
        let expected = [false, true, false]

        authenticationManager.sendPasswordResetToReturnValue = .just(())

        let viewModel = EmailSignInViewModel()
        viewModel.$loading
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        viewModel.email = #function
        viewModel.forgotTapped()

        waitForExpectations(timeout: 1)
    }

    func testThatForgotErrorIsPresented() {
        let expectedError = MockError.mock(id: #function)

        authenticationManager.sendPasswordResetToReturnValue = .error(expectedError)

        let viewModel = EmailSignInViewModel()
        viewModel.email = #function
        viewModel.forgotTapped()

        XCTAssertEqual(viewModel.error as? MockError, expectedError)
    }
}
