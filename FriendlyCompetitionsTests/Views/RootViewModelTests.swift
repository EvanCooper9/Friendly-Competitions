import Combine
import ECKit
import Factory
import XCTest

@testable import FriendlyCompetitions

final class RootViewModelTests: FCTestCase {

    override func setUp() {
        super.setUp()
        appState.deepLink = .never()
        appState.rootTab = .never()
    }

    func testThatTabChangesToHomeOnDeepLink() {
        let expectation = self.expectation(description: #function)
        
        let deepLinkPublisher = PassthroughSubject<DeepLink?, Never>()
        appState.deepLink = deepLinkPublisher.eraseToAnyPublisher()

        let viewModel = RootViewModel()
        viewModel.tab = .explore
        viewModel.$tab
            .expect(.explore, .home, expectation: expectation)
            .store(in: &cancellables)
        
        deepLinkPublisher.send(.user(id: User.evan.id))
        
        waitForExpectations(timeout: 1)
    }

    func testThatRooTabChanges() {
        let expectation = self.expectation(description: #function)

        let rootTabSubject = PassthroughSubject<RootTab, Never>()
        appState.rootTab = rootTabSubject.eraseToAnyPublisher()

        let viewModel = RootViewModel()
        viewModel.$tab
            .expect(.home, .explore, .home, expectation: expectation)
            .store(in: &cancellables)

        rootTabSubject.send(.explore)
        scheduler.advance()
        rootTabSubject.send(.home)
        scheduler.advance()

        waitForExpectations(timeout: 1)
    }
}
