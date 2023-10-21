@testable import Friendly_Competitions
import XCTest

final class NotificationsAppServiceTests: FCTestCase {
    func testThatNotificationsManagerIsSetUp() {
        let service = NotificationsAppService()
        service.willFinishLaunching()
        XCTAssertTrue(notificationsManager.setUpCalled)
    }
}
