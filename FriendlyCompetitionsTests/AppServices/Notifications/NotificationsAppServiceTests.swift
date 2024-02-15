@testable import FriendlyCompetitions
import XCTest

final class NotificationsAppServiceTests: FCTestCase {
    func testThatNotificationsManagerIsSetUp() {
        let service = NotificationsAppService()
        service.didFinishLaunching()
        XCTAssertTrue(notificationsManager.setUpCalled)
    }
}
