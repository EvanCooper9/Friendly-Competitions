import Combine
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class RootViewModelTests: FCTestCase {
    
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
}
