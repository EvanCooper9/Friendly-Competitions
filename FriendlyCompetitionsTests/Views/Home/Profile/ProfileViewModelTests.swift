import Combine
import ECKit
import Factory
import XCTest

@testable import FriendlyCompetitions

final class SettingsViewModelTests: FCTestCase {

    override func setUp() {
        super.setUp()

        featureFlagManager.valueForBoolFeatureFlagFeatureFlagBoolBoolReturnValue = false
        userManager.updateWithReturnValue = .never()
    }

    func testThatIsAnonymouseAccountIsCorrect() {
        let expectation = self.expectation(description: #function)
        let expected = [false, false, true]

        let userSubject = PassthroughSubject<User, Never>()
        userManager.userPublisher = userSubject.eraseToAnyPublisher()

        let viewModel = SettingsViewModel()
        viewModel.$isAnonymousAccount
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        userSubject.send(.init(id: #function, name: "name", email: "evan@mail.com"))
        userSubject.send(.init(id: #function, name: "name", email: "evan@mail.com", isAnonymous: false))
        userSubject.send(.init(id: #function, name: "name", email: "evan@mail.com", isAnonymous: true))

        waitForExpectations(timeout: 1)
    }
}
