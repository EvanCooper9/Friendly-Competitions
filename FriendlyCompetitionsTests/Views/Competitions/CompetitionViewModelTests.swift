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
        bannerManager.banners = .never()
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

    func testThatBannersAreCorrect() {
        appState.didBecomeActive = .just(true)
        featureFlagManager.valueForDoubleFeatureFlagFeatureFlagDoubleDoubleReturnValue = 0
        healthKitManager.shouldRequestReturnValue = .just(true)
        notificationsManager.permissionStatusReturnValue = .just(.authorized)

        let competition = Competition.mock
        let expectedBanners: [Banner] = [
            .healthKitPermissionsMissing(permissions: [.activitySummaryType, .activeEnergy, .appleExerciseTime, .appleMoveTime, .appleStandTime, .appleStandHour]),
            .backgroundRefreshDenied,
            .competitionResultsCalculating(competition: competition)
        ]
        bannerManager.banners = .just(expectedBanners)

        let viewModel = CompetitionViewModel(competition: competition)

        XCTAssertEqual(viewModel.banners, expectedBanners)
    }

    func testTappingBanner() {
        bannerManager.tappedReturnValue = .never()
        let banner = Banner.backgroundRefreshDenied
        let viewModel = CompetitionViewModel(competition: .mock)
        viewModel.tapped(banner)
        XCTAssertEqual(bannerManager.tappedReceivedInvocations, [banner])
    }

    func testDismissingBanner() {
        bannerManager.dismissedReturnValue = .never()
        let banner = Banner.backgroundRefreshDenied
        let viewModel = CompetitionViewModel(competition: .mock)
        viewModel.dismissed(banner)
        XCTAssertEqual(bannerManager.dismissedReceivedInvocations, [banner])
    }
}
