import Combine
import CombineSchedulers
import ECKit
import Factory
import XCTest

@testable import Friendly_Competitions

final class CompetitionResultsViewModelTests: FCTestCase {

    private var activitySummaryManager: ActivitySummaryManagingMock!
    private var competitionsManager: CompetitionsManagingMock!
    private var premiumManager: PremiumManagingMock!
    private var scheduler: TestSchedulerOf<RunLoop>!
    private var userManager: UserManagingMock!
    private var workoutManager: WorkoutManagingMock!

    private var cancellables: Cancellables!

    override func setUp() {
        super.setUp()

        activitySummaryManager = .init()
        competitionsManager = .init()
        premiumManager = .init()
        scheduler = .init(now: .init(.now))
        userManager = .init()
        workoutManager = .init()

        cancellables = .init()

        Container.shared.activitySummaryManager.register { self.activitySummaryManager }
        Container.shared.competitionsManager.register { self.competitionsManager }
        Container.shared.premiumManager.register { self.premiumManager }
        Container.shared.scheduler.register { self.scheduler.eraseToAnyScheduler() }
        Container.shared.userManager.register { self.userManager }
        Container.shared.workoutManager.register { self.workoutManager }

        activitySummaryManager.activitySummariesInReturnValue = .just([])
        premiumManager.premium = .just(nil)
        userManager.user = .evan
        userManager.userPublisher = .just(userManager.user)
    }

    func testThatRangesAreInCorrectOrder() {
        let expectation = self.expectation(description: #function)
        
        let expectedResults: [CompetitionResult] = [
            .init(
                id: "1",
                start: .now.advanced(by: -10.days),
                end: .now.advanced(by: -8.days),
                participants: []
            ),
            .init(
                id: "2",
                start: .now.advanced(by: -6.days),
                end: .now.advanced(by: -4.days),
                participants: []
            )
        ]

        let expectedRanges = expectedResults
            .reversed() // newest first
            .enumerated()
            .map { index, result in
                range(for: result, selected: index == 0, locked: index != 0)
            }

        competitionsManager.resultsForReturnValue = .just(expectedResults)
        competitionsManager.standingsForResultIDReturnValue = .just([])

        let competition = Competition.mock
        let viewModel = CompetitionResultsViewModel(competition: competition)

        scheduler.advance()

        viewModel.$ranges
            .expect(expectedRanges, expectation: expectation)
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    // MARK: - Private Methods

    private func range(for result: CompetitionResult, selected: Bool = false, locked: Bool = false) -> CompetitionResultsDateRange {
        .init(
            start: result.start,
            end: result.end,
            selected: selected,
            locked: locked
        )
    }
}
