@testable import FriendlyCompetitions
import XCTest

final class FirebaseImageViewModelTests: FCTestCase {
    func testThatImageDataIsSetCorrectly() {
        let expectedData = Data([1, 2, 3])
        storageManager.dataForReturnValue = .just(expectedData)
        let viewModel = FirebaseImageViewModel(path: #function)
        scheduler.advance()
        XCTAssertEqual(viewModel.imageData, expectedData)
        XCTAssertEqual(storageManager.dataForReceivedStoragePath, #function)
    }

    func testThatFailedIsSet() {
        storageManager.dataForReturnValue = .error(MockError.mock(id: #function))
        let viewModel = FirebaseImageViewModel(path: #function)
        scheduler.advance()
        XCTAssertTrue(viewModel.failed)
    }

    func testDownloadImage() {
        storageManager.dataForReturnValue = .just(Data([1, 2, 3]))
        let viewModel = FirebaseImageViewModel(path: #function)
        scheduler.advance()
        viewModel.downloadImage()
        scheduler.advance()
        XCTAssertEqual(storageManager.dataForCallsCount, 2)
    }
}
