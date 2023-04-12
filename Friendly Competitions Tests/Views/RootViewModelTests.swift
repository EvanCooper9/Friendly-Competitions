import Combine
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class RootViewModelTests: FCTestCase {
    
    private var deepLinkManager: DeepLinkManagingMock!
    private var cancellables: Cancellables!
    
    override func setUp() {
        super.setUp()
        deepLinkManager = .init()
        container.deepLinkManager.register { self.deepLinkManager }
        cancellables = .init()
    }
    
    func testThatTabChangesToHomeOnDeepLink() {
        let expectation = self.expectation(description: #function)
        
        let deepLinkPublisher = PassthroughSubject<DeepLink?, Never>()
        deepLinkManager.deepLink = deepLinkPublisher.eraseToAnyPublisher()
        
        let viewModel = RootViewModel()
        viewModel.tab = .explore
        viewModel.$tab
            .expect(.explore, .home, expectation: expectation)
            .store(in: &cancellables)
        
        deepLinkPublisher.send(.user(id: User.evan.id))
        
        waitForExpectations(timeout: 1)
    }
}
