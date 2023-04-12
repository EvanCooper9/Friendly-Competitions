import Combine
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class RootViewModelTests: FCTestCase {
    
    private var appState: AppStateProvidingMock!
    private var cancellables: Cancellables!
    
    override func setUp() {
        super.setUp()
        appState = .init()
        container.appState.register { self.appState }
        cancellables = .init()
    }
    
    override func tearDown() {
        super.tearDown()
        appState = nil
        cancellables = nil
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

    // MARK: - Private Methods

    private func registerDependencies() {

    }
}
