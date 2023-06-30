import Combine
import CombineSchedulers
import ECKit
import Foundation
import XCTest

@testable import Friendly_Competitions

final class CompetitionViewModelTests: FCTestCase {

    private var activitySummaryManager: ActivitySummaryManagingMock!
    private var api: APIMock!
    private var appState: AppStateProvidingMock!
    private var competitionsManager: CompetitionsManagingMock!
    private var healthKitManager: HealthKitManagingMock!
    private var notificationsManager: NotificationsManagingMock!
    private var scheduler: TestSchedulerOf<RunLoop>!
    private var searchManager: SearchManagingMock!
    private var userManager: UserManagingMock!
    private var workoutManager: WorkoutManagingMock!

    private var cancellables: Cancellables!

    override func setUp() {
        super.setUp()

        activitySummaryManager = .init()
        api = .init()
        appState = .init()
        competitionsManager = .init()
        healthKitManager = .init()
        notificationsManager = .init()
        scheduler = .init(now: .init(.now))
        searchManager = .init()
        userManager = .init()
        workoutManager = .init()

        cancellables = .init()

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

    func testThatBannerShowsMissingPermissions() {
        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(true)

        let viewModel = CompetitionViewModel(competition: .mock)
        scheduler.advance(by: .seconds(1))

        XCTAssertEqual(viewModel.banner, .missingCompetitionPermissions)
    }

    func testThatBannerShowsMissingData() {
        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(false)
        activitySummaryManager.activitySummariesInReturnValue = .just([])

        let viewModel = CompetitionViewModel(competition: .mock)
        scheduler.advance(by: .seconds(1))

        XCTAssertEqual(viewModel.banner, .missingCompetitionData)
    }

    func testThatBannerIsNil() {
        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(false)
        activitySummaryManager.activitySummariesInReturnValue = .just([.mock])

        let viewModel = CompetitionViewModel(competition: .mock)
        scheduler.advance(by: .seconds(1))

        XCTAssertNil(viewModel.banner)
    }

    func testThatTappingBannerRequestsPermissions() {
        let expectation = self.expectation(description: #function)
        let expected = [nil, Banner.missingCompetitionPermissions, nil]

        appState.didBecomeActive = .just(true)
        healthKitManager.shouldRequestReturnValue = .just(true)

        let viewModel = CompetitionViewModel(competition: .mock)
        viewModel.$banner
            .removeDuplicates()
            .print("banner")
            .collect(expected.count)
            .expect(expected, expectation: expectation)
            .store(in: &cancellables)

        scheduler.advance(by: .seconds(1))

        activitySummaryManager.activitySummariesInReturnValue = .just([.mock])
        healthKitManager.shouldRequestReturnValue = .just(false)
        healthKitManager.requestReturnValue = .just(())
        
        viewModel.tapped(banner: .missingCompetitionPermissions)
        scheduler.advance()

        waitForExpectations(timeout: 1)
        XCTAssertEqual(healthKitManager.requestCallsCount, 1)
    }
}
