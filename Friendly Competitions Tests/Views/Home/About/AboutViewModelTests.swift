@testable import Friendly_Competitions
import XCTest

final class AboutViewModelTests: FCTestCase {
    func testBugReportURLIsCorrect() {
        let user = User.evan
        userManager.user = user
        let viewModel = AboutViewModel()
        XCTAssertEqual(viewModel.bugReportURL, .bugReport(with: user.id))
    }

    func testFeatureRequestURLIsCorrect() {
        let user = User.evan
        userManager.user = user
        let viewModel = AboutViewModel()
        XCTAssertEqual(viewModel.featureRequestURL, .featureRequest(with: user.id))
    }
}
