import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class EmailSignInViewModelTests: FCTestCase {

    func testThatSignInTriggersLoading() {
        let expectation = self.expectation(description: #function)
        let expected = [false, true, false]

        authenticationManager.signInWithReturnValue = .just(())

        let viewModel = makeViewModel()
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

        let viewModel = makeViewModel()
        viewModel.continueTapped()

        XCTAssertEqual(viewModel.inputType, .signIn)
        XCTAssertEqual(viewModel.error as? MockError, expectedError)
    }

    func testThatSignUpErrorIsPresented() {
        let expectedError = MockError.mock(id: #function)

        authenticationManager.signUpNameEmailPasswordPasswordConfirmationReturnValue = .error(expectedError)

        let viewModel = makeViewModel()
        viewModel.changeInputTypeTapped()
        viewModel.continueTapped()

        XCTAssertEqual(viewModel.inputType, .signUp)
        XCTAssertEqual(viewModel.error as? MockError, expectedError)
    }

    func testThatForgotTriggersPasswordReset() {
        let expectedEmail = #function

        authenticationManager.sendPasswordResetToReturnValue = .just(())

        let viewModel = makeViewModel()
        viewModel.email = expectedEmail
        viewModel.forgotTapped()
        XCTAssertTrue(authenticationManager.sendPasswordResetToCalled)
        XCTAssertEqual(authenticationManager.sendPasswordResetToReceivedInvocations, [expectedEmail])
    }

    func testThatForgotTriggersLoading() {
        let expectation = self.expectation(description: #function)
        let expected = [false, true, false]

        authenticationManager.sendPasswordResetToReturnValue = .just(())

        let viewModel = makeViewModel()
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

        let viewModel = makeViewModel()
        viewModel.email = #function
        viewModel.forgotTapped()

        XCTAssertEqual(viewModel.error as? MockError, expectedError)
    }

    func testThatCanSwitchInputType() {
        XCTAssertTrue(makeViewModel(canSwitchInputType: true).canSwitchInputType)
        XCTAssertFalse(makeViewModel(canSwitchInputType: false).canSwitchInputType)
    }

    func testThatChangeInputTypeWorks() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.inputType, .signIn)
        viewModel.changeInputTypeTapped()
        XCTAssertEqual(viewModel.inputType, .signUp)
        viewModel.changeInputTypeTapped()
        XCTAssertEqual(viewModel.inputType, .signIn)
    }

    // MARK: - Private

    private func makeViewModel(startingInputType: EmailSignInViewInputType = .signIn, canSwitchInputType: Bool = true) -> EmailSignInViewModel {
        EmailSignInViewModel(startingInputType: startingInputType, canSwitchInputType: canSwitchInputType)
    }
}
