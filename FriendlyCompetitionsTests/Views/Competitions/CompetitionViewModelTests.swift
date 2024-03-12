import Combine
import CombineSchedulers
import ECKit
import Foundation
import XCTest

@testable import FriendlyCompetitions

final class CompetitionViewModelTests: FCTestCase {

    override func setUp() {
        super.setUp()

        activitySummaryManager.activitySummariesInReturnValue = .never()
        appState.didBecomeActive = .never()
        competitionsManager.competitionPublisherForReturnValue = .never()
        competitionsManager.resultsForReturnValue = .never()
        competitionsManager.standingsPublisherForLimitReturnValue = .never()
        competitionsManager.unseenResults = .never()
        healthKitManager.permissionsChanged = .just(())
        healthKitManager.shouldRequestReturnValue = .never()
        notificationsManager.requestPermissionsReturnValue = .never()
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

        let expectedBanner = Banner.healthKitPermissionsMissing(permissions: [.activitySummaryType, .activeEnergy, .appleExerciseTime, .appleMoveTime, .appleStandTime, .appleStandHour])
        XCTAssertEqual(viewModel.banners, [expectedBanner])
    }

    func testThatBannersHasHealthKitDataMissing() {
        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(false)
        activitySummaryManager.activitySummariesInReturnValue = .just([])
        notificationsManager.permissionStatusReturnValue = .just(.authorized)

        let viewModel = CompetitionViewModel(competition: .mock)
        scheduler.advance(by: .seconds(1))

        let expectedBanner = Banner.healthKitDataMissing(dataType: [.activitySummaryType, .activeEnergy, .appleExerciseTime, .appleMoveTime, .appleStandTime, .appleStandHour])
        XCTAssertEqual(viewModel.banners, [expectedBanner])
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

        let healthKitBanner = Banner.healthKitPermissionsMissing(permissions: [.activitySummaryType, .activeEnergy, .appleExerciseTime, .appleMoveTime, .appleStandTime, .appleStandHour])
        let expected = [
            [],
            [healthKitBanner],
            []
        ]

        activitySummaryManager.activitySummariesInReturnValue = .just([])
        appState.didBecomeActive = .just(true)
        competitionsManager.competitions = .just([])
        healthKitManager.permissionsChanged = .just(())
        healthKitManager.shouldRequestReturnValue = .just(true)
        notificationsManager.permissionStatusReturnValue = .just(.authorized)

        let viewModel = CompetitionViewModel(competition: .mock)
        viewModel.$banners
            .removeDuplicates()
            .print("BANNERS")
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        scheduler.advance(by: .seconds(1))

        activitySummaryManager.activitySummariesInReturnValue = .just([.mock])
        healthKitManager.shouldRequestReturnValue = .just(false)
        healthKitManager.requestReturnValue = .just(())
        
        viewModel.tapped(banner: healthKitBanner)
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
