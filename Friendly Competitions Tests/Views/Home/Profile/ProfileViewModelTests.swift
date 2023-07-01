import Combine
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class ProfileViewModelTests: FCTestCase {

    private var authenticationManager = AuthenticationManagingMock()
    private var premiumManager = PremiumManagingMock()
    private var userManager = UserManagingMock()
    private var cancellables = Cancellables()

    override func setUp() {
        super.setUp()

        container.authenticationManager.register { self.authenticationManager }
        container.premiumManager.register { self.premiumManager }
        container.userManager.register { self.userManager }

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
