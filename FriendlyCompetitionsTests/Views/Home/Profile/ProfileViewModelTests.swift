import Combine
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class ProfileViewModelTests: FCTestCase {

    override func setUp() {
        super.setUp()

        featureFlagManager.valueForBoolReturnValue = false
        premiumManager.premium = .never()
        userManager.updateWithReturnValue = .never()
    }

    func testThatIsAnonymouseAccountIsCorrect() {
        let expectation = self.expectation(description: #function)
        let expected = [false, false, true]

        let userSubject = PassthroughSubject<User, Never>()
        userManager.userPublisher = userSubject.eraseToAnyPublisher()

        let viewModel = ProfileViewModel()
        viewModel.$isAnonymousAccount
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        userSubject.send(.init(id: #function, name: "name"))
        userSubject.send(.init(id: #function, name: "name", isAnonymous: false))
        userSubject.send(.init(id: #function, name: "name", isAnonymous: true))

        waitForExpectations(timeout: 1)
    }
}