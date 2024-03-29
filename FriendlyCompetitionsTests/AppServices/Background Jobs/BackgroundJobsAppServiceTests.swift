@testable import FriendlyCompetitions
import XCTest

final class BackgroundJobsAppServiceTests: FCTestCase {
    func testThatBackgroundNotificationReceivedAnalyticEventIsLogged() {
        let service = BackgroundJobsAppService()
        service.didReceiveRemoteNotification(with: [:])
            .sink()
            .store(in: &cancellables)
        XCTAssertTrue(analyticsManager.logEventAnalyticsEventVoidReceivedInvocations.contains(.backgroundNotificationReceived))
    }

    func testThatBackgroundNotificationfailedToParseJobAnalyticEventIsLogged() {
        let service = BackgroundJobsAppService()

        // fails
        service.didReceiveRemoteNotification(with: [:])
            .sink()
            .store(in: &cancellables)

        // fails
        service.didReceiveRemoteNotification(with: ["customData": [String: Any]()])
            .sink()
            .store(in: &cancellables)

        // does not fail
        service.didReceiveRemoteNotification(with: ["customData": ["backgroundJob": [String: Any]()]])
            .sink()
            .store(in: &cancellables)

        let failedCount = analyticsManager.logEventAnalyticsEventVoidReceivedInvocations
            .filter { $0 == .backgroundNotificationFailedToParseJob }
            .count

        XCTAssertEqual(failedCount, 2)
    }
}
