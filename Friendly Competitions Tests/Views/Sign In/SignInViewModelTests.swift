import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class SignInViewModelTests: XCTestCase {
    
    private var appState: AppStateProvidingMock!
    private var authenticationManager: AuthenticationManagingMock!
    
    private var cancellables: Cancellables!
    
    override func setUp() {
        super.setUp()
        appState = .init()
        authenticationManager = .init()
        cancellables = .init()
        
        Container.appState.register { self.appState }
        Container.authenticationManager.register { self.authenticationManager }
    }

    override func tearDown() {
        appState = nil
        authenticationManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testThatInputsAreEmpty() {
        let viewModel = SignInViewModel()
        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertEqual(viewModel.passwordConfirmation, "")
    }
}