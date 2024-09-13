@testable import FriendlyCompetitions
import XCTest

final class FirebaseImageViewModelTests: FCTestCase {
    func testDownloadSucceeded() {
        let expectedData = Data([1, 2, 3])
        storageManager.getReturnValue = .just(expectedData)
        let viewModel = FirebaseImageViewModel(path: #function)
        scheduler.advance()
        XCTAssertEqual(viewModel.imageData, expectedData)
        XCTAssertEqual(storageManager.getReceivedPath, #function)
    }

    func testDownloadFailed() {
        storageManager.getReturnValue = .error(MockError.mock(id: #function))
        let viewModel = FirebaseImageViewModel(path: #function)
        scheduler.advance()
        XCTAssertTrue(viewModel.failed)
    }
}
