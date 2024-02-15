@testable import FriendlyCompetitions
import XCTest

final class VerifyEmailViewModelTests: FCTestCase {
    
    func testUserIsCorrect() {
        let user = User.evan
        userManager.user = user
        let viewModel = VerifyEmailViewModel()
        XCTAssertEqual(viewModel.user, user)
    }

    func testThatTappingBackSignsOut() {
        userManager.user = .evan
        let viewModel = VerifyEmailViewModel()
        viewModel.back()
        XCTAssertTrue(authenticationManager.signOutCalled)
    }

    func testThatResendVerificationWorks() {
        userManager.user = .evan
        authenticationManager.resendEmailVerificationReturnValue = .just(())

        let viewModel = VerifyEmailViewModel()
        viewModel.resendVerification()
        scheduler.advance()
        XCTAssertTrue(authenticationManager.resendEmailVerificationCalled)
        XCTAssertTrue(appState.pushHudCalled)
        XCTAssertEqual(appState.pushHudReceivedHud, .success(text: L10n.VerifyEmail.reSent))
    }

    func testThatResendVerificationFails() {
        userManager.user = .evan
        let expectedError = MockError.mock(id: #function)
        authenticationManager.resendEmailVerificationReturnValue = .error(expectedError)

        let viewModel = VerifyEmailViewModel()
        viewModel.resendVerification()
        scheduler.advance()
        XCTAssertTrue(authenticationManager.resendEmailVerificationCalled)
        XCTAssertTrue(appState.pushHudCalled)
        XCTAssertEqual(appState.pushHudReceivedHud, .error(expectedError))
    }

    func testThatItChecksEmailVerificationEvery5Seconds() {
        userManager.user = .evan
        authenticationManager.checkEmailVerificationReturnValue = .just(())

        let viewModel = VerifyEmailViewModel()
        retainDuringTest(viewModel)

        let elapsedTimeInSeconds = 100
        scheduler.advance(by: .seconds(elapsedTimeInSeconds))

        XCTAssertEqual(authenticationManager.checkEmailVerificationCallsCount, elapsedTimeInSeconds / 5)
    }

    func testThatItChecksEmailVerificationEvery5SecondsOnError() {
        userManager.user = .evan
        authenticationManager.checkEmailVerificationReturnValue = .error(MockError.mock(id: #function))

        let viewModel = VerifyEmailViewModel()
        retainDuringTest(viewModel)

        let elapsedTimeInSeconds = 100
        scheduler.advance(by: .seconds(elapsedTimeInSeconds))

        XCTAssertEqual(authenticationManager.checkEmailVerificationCallsCount, elapsedTimeInSeconds / 5)
    }
}
