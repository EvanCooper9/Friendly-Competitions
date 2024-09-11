@testable import FriendlyCompetitions
import XCTest

final class FirebaseImageViewModelTests: FCTestCase {
    func testThatImageDataIsSetCorrectly() {
        let expectedData = Data([1, 2, 3])
        storageManager.getReturnValue = .just(expectedData)
        let viewModel = FirebaseImageViewModel(path: #function)
        scheduler.advance()
        XCTAssertEqual(viewModel.imageData, expectedData)
        XCTAssertEqual(storageManager.getReceivedPath, #function)
    }

    func testThatFailedIsSet() {
        storageManager.getReturnValue = .error(MockError.mock(id: #function))
        let viewModel = FirebaseImageViewModel(path: #function)
        scheduler.advance()
        XCTAssertTrue(viewModel.failed)
    }

    func testDownloadImage() {
        storageManager.getReturnValue = .just(Data([1, 2, 3]))
        let viewModel = FirebaseImageViewModel(path: #function)
        scheduler.advance()
        XCTAssertEqual(storageManager.getCallsCount, 2)
    }
}
