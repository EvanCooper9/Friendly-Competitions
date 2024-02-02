import Combine
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class CreateAccountViewModelTests: FCTestCase {

    private let anonymousUser = User(id: "123", name: "Anonymous", isAnonymous: true)

    func testThatSignInWithAppleIsTriggered() {
        authenticationManager.signInWithReturnValue = .just(())
        userManager.userPublisher = .just(anonymousUser)

        let viewModel = CreateAccountViewModel()
        viewModel.signInWithAppleTapped()

        XCTAssertEqual(authenticationManager.signInWithReceivedInvocations, [.apple])
    }

    func testThatSignInWithAppleTriggersLoading() {
        let expectation = self.expectation(description: #function)
        let expected = [false, true, false]

        authenticationManager.signInWithReturnValue = .just(())
        userManager.userPublisher = .just(anonymousUser)

        let viewModel = CreateAccountViewModel()
        viewModel.$loading
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        viewModel.signInWithAppleTapped()

        waitForExpectations(timeout: 1)
    }

    func testThatSignInWithAppleTriggersDismiss() {
        let expectation = self.expectation(description: #function)
        let expected = [false, true]

        authenticationManager.signInWithReturnValue = .just(())
        userManager.userPublisher = .just(anonymousUser)

        let viewModel = CreateAccountViewModel()
        viewModel.$dismiss
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        viewModel.signInWithAppleTapped()

        waitForExpectations(timeout: 1)
    }

    func testThatSignInWithAppleErrorIsEmitted() {
        let expectedError = MockError.mock(id: #function)
        authenticationManager.signInWithReturnValue = .error(expectedError)
        userManager.userPublisher = .just(anonymousUser)

        let viewModel = CreateAccountViewModel()
        XCTAssertNil(viewModel.error)

        viewModel.signInWithAppleTapped()

        XCTAssertEqual(viewModel.error as? MockError, expectedError)
    }

    func testThatShowEmailSignInIsTriggered() {
        let expectation = self.expectation(description: #function)
        let expected = [false, true]

        userManager.userPublisher = .just(anonymousUser)

        let viewModel = CreateAccountViewModel()
        viewModel.$showEmailSignIn
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        viewModel.signInWithEmailTapped()

        waitForExpectations(timeout: 1)
    }
}
