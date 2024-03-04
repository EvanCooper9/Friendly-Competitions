@testable import FriendlyCompetitions
import XCTest

final class ActivitySummaryInfoViewModelTests: FCTestCase {

    override func setUp() {
        super.setUp()
        healthKitManager.permissionsChanged = .never()
    }

    func testThatActivitySummaryIsCorrectForLocalSource() {
        let expectedActivitySummary = ActivitySummary.mock
        activitySummaryManager.activitySummary = .just(expectedActivitySummary)
        healthKitManager.shouldRequestReturnValue = .never()

        let viewModel = ActivitySummaryInfoViewModel(source: .local)
        scheduler.advance()
        XCTAssertEqual(viewModel.activitySummary, expectedActivitySummary)
    }

    func testThatActivitySummaryIsCorrectForOtherSource() {
        let expectedActivitySummary = ActivitySummary.mock
        let viewModel = ActivitySummaryInfoViewModel(source: .other(expectedActivitySummary))
        XCTAssertEqual(viewModel.activitySummary, expectedActivitySummary)
    }

    func testRequestPermissionsTapped() {
        activitySummaryManager.activitySummary = .never()
        healthKitManager.shouldRequestReturnValue = .never()

        healthKitManager.requestReturnValue = .just(())

        let viewModel = ActivitySummaryInfoViewModel(source: .local)
        viewModel.requestPermissionsTapped()
        scheduler.advance()
        XCTAssertFalse(viewModel.shouldRequestPermissions)

        let expectedPermissions: [HealthKitPermissionType] = [
            .activitySummaryType,
            .activeEnergy,
            .appleExerciseTime,
            .appleMoveTime,
            .appleStandTime,
            .appleStandHour
        ]

        XCTAssertEqual(healthKitManager.requestReceivedPermissions, expectedPermissions)
    }
}
