import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class SignInViewModelTests: FCTestCase {
    
    private var appState: AppStateProvidingMock!
    private var authenticationManager: AuthenticationManagingMock!
    
    private var cancellables: Cancellables!
    
    override func setUp() {
        super.setUp()
        appState = .init()
        authenticationManager = .init()
        cancellables = .init()
        
        container.appState.register { self.appState }
        container.authenticationManager.register { self.authenticationManager }
    }
    
    func testThatInputsAreEmpty() {
        let viewModel = SignInViewModel()
        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertEqual(viewModel.passwordConfirmation, "")
    }
}
