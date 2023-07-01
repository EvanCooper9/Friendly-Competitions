import Combine
import CombineSchedulers
import ECKit
import Foundation
import XCTest

@testable import Friendly_Competitions

final class CompetitionViewModelTests: FCTestCase {

    private var activitySummaryManager = ActivitySummaryManagingMock()
    private var api = APIMock()
    private var appState = AppStateProvidingMock()
    private var competitionsManager = CompetitionsManagingMock()
    private var healthKitManager = HealthKitManagingMock()
    private var notificationsManager = NotificationsManagingMock()
    private var scheduler = TestSchedulerOf<RunLoop>(now: .init(.now))
    private var searchManager = SearchManagingMock()
    private var userManager = UserManagingMock()
    private var workoutManager = WorkoutManagingMock()
    private var cancellables = Cancellables()

    override func setUp() {
        super.setUp()

        container.activitySummaryManager.register { self.activitySummaryManager }
        container.api.register { self.api }
        container.appState.register { self.appState }
        container.competitionsManager.register { self.competitionsManager }
        container.healthKitManager.register { self.healthKitManager }
        container.notificationsManager.register { self.notificationsManager }
        container.scheduler.register { self.scheduler.eraseToAnyScheduler() }
        container.searchManager.register { self.searchManager }
        container.userManager.register { self.userManager }
        container.workoutManager.register { self.workoutManager }

        appState.didBecomeActive = .never()
        competitionsManager.competitionPublisherForReturnValue = .never()
        competitionsManager.resultsForReturnValue = .never()
        competitionsManager.standingsPublisherForReturnValue = .never()
        healthKitManager.shouldRequestReturnValue = .never()
        searchManager.searchForUsersWithIDsReturnValue = .never()
        userManager.user = .evan
        userManager.userPublisher = .just(.evan)
    }

    func testThatBannerHasHealthKitPermissionsMissing() {
        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(true)
        notificationsManager.permissionStatusReturnValue = .just(.authorized)

        let viewModel = CompetitionViewModel(competition: .mock)
        scheduler.advance(by: .seconds(1))

        XCTAssertEqual(viewModel.banners, [.healthKitPermissionsMissing])
    }

    func testThatBannersHasHealthKitDataMissing() {
        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(false)
        activitySummaryManager.activitySummariesInReturnValue = .just([])
        notificationsManager.permissionStatusReturnValue = .just(.authorized)

        let viewModel = CompetitionViewModel(competition: .mock)
        scheduler.advance(by: .seconds(1))

        XCTAssertEqual(viewModel.banners, [.healthKitDataMissing])
    }

    func testThatBannersHasNotificationPermissionsDenied() {
        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(false)
        activitySummaryManager.activitySummariesInReturnValue = .just([.mock])
        notificationsManager.permissionStatusReturnValue = .just(.denied)

        let viewModel = CompetitionViewModel(competition: .mock)
        scheduler.advance(by: .seconds(1))

        XCTAssertEqual(viewModel.banners, [.notificationPermissionsDenied])
    }

    func testThatBannersHasNotificationPermissionsMissing() {
        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(false)
        activitySummaryManager.activitySummariesInReturnValue = .just([.mock])
        notificationsManager.permissionStatusReturnValue = .just(.notDetermined)

        let viewModel = CompetitionViewModel(competition: .mock)
        scheduler.advance(by: .seconds(1))

        XCTAssertEqual(viewModel.banners, [.notificationPermissionsMissing])
    }

    func testThatBannerIsNil() {
        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(false)
        activitySummaryManager.activitySummariesInReturnValue = .just([.mock])
        notificationsManager.permissionStatusReturnValue = .just(.authorized)

        let viewModel = CompetitionViewModel(competition: .mock)
        scheduler.advance(by: .seconds(1))

        XCTAssertTrue(viewModel.banners.isEmpty)
    }

    func testThatTappingBannerRequestsHealthKitPermissions() {
        let expectation = self.expectation(description: #function)
        let expected = [[], [Banner.healthKitPermissionsMissing], []]

        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(true)
        notificationsManager.permissionStatusReturnValue = .just(.authorized)

        let viewModel = CompetitionViewModel(competition: .mock)
        viewModel.$banners
            .removeDuplicates()
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        scheduler.advance(by: .seconds(1))

        activitySummaryManager.activitySummariesInReturnValue = .just([.mock])
        healthKitManager.shouldRequestReturnValue = .just(false)
        healthKitManager.requestReturnValue = .just(())
        
        viewModel.tapped(banner: .healthKitPermissionsMissing)
        scheduler.advance()

        waitForExpectations(timeout: 1)
        XCTAssertEqual(healthKitManager.requestCallsCount, 1)
    }

    func testThatTappingBannerRequestsNotificationPermissions() {
        let expectation = self.expectation(description: #function)
        let expected = [[], [Banner.notificationPermissionsMissing], []]

        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(false)
        activitySummaryManager.activitySummariesInReturnValue = .just([.mock])
        notificationsManager.permissionStatusReturnValue = .just(.notDetermined)

        let viewModel = CompetitionViewModel(competition: .mock)
        viewModel.$banners
            .removeDuplicates()
            .print("banners")
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        scheduler.advance(by: .seconds(1))

        notificationsManager.permissionStatusReturnValue = .just(.authorized)
        notificationsManager.requestPermissionsReturnValue = .just(true)

        viewModel.tapped(banner: .notificationPermissionsMissing)
        scheduler.advance()

        waitForExpectations(timeout: 1)
        XCTAssertEqual(notificationsManager.requestPermissionsCallsCount, 1)
    }
}
