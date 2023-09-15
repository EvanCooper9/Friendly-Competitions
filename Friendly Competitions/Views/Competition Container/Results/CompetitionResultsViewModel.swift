import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class CompetitionResultsViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published private(set) var dataPoints = [CompetitionResultsDataPoint]()
    @Published private(set) var loading = false

    // MARK: - Private Properties

    private let competition: Competition

    @Injected(\.activitySummaryManager) private var activitySummaryManager
    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.scheduler) private var scheduler
    @Injected(\.stepCountManager) private var stepCountManager
    @Injected(\.userManager) private var userManager
    @Injected(\.workoutManager) private var workoutManager

    // MARK: - Lifecycle

    init(competition: Competition, result: CompetitionResult, previousResult: CompetitionResult?) {
        self.competition = competition

        Publishers
            .CombineLatest(
                standingsDataPoints(currentResult: result, previousResult: previousResult),
                scoringDataPoints(currentResult: result, previousResult: previousResult)
            )
            .first()
            .map(+)
            .isLoading(set: \.loading, on: self)
            .eraseToAnyPublisher()
            .receive(on: scheduler)
            .assign(to: &$dataPoints)
    }

    // MARK: - Private Methods

    private func standingsDataPoints(currentResult: CompetitionResult, previousResult: CompetitionResult?) -> AnyPublisher<[CompetitionResultsDataPoint], Never> {
        let previousStandings: AnyPublisher<[Competition.Standing]?, Never> = {
            guard let previousResult else { return .just(nil) }
            return competitionsManager
                .standings(for: competition.id, resultID: previousResult.id)
                .map { $0 as [Competition.Standing]? }
                .catchErrorJustReturn(nil)
                .eraseToAnyPublisher()
        }()

        let currentStandings = competitionsManager
            .standings(for: competition.id, resultID: currentResult.id)
            .catchErrorJustReturn([])

        return Publishers
            .CombineLatest3(currentStandings, previousStandings, userManager.userPublisher)
            .map { currentStandings, previousStandings, user -> [CompetitionResultsDataPoint] in
                var dataPoints = [CompetitionResultsDataPoint]()

                if let standing = currentStandings.first(where: { $0.userId == user.id }) {
                    let previous = previousStandings?.first(where: { $0.userId == user.id })
                    dataPoints.append(.rank(
                        current: standing.rank,
                        previous: previous?.rank
                    ))
                    dataPoints.append(.points(
                        current: standing.points,
                        previous: previous?.points
                    ))
                }

                dataPoints.append(.standings(
                    currentStandings
                        .sorted(by: \.rank)
                        .map { standing in
                            .init(
                                userId: standing.userId,
                                rank: standing.rank,
                                points: standing.points,
                                isHighlighted: standing.userId == user.id
                            )
                        }
                ))
                return dataPoints
            }
            .eraseToAnyPublisher()
    }

    private func scoringDataPoints(currentResult: CompetitionResult, previousResult: CompetitionResult?) -> AnyPublisher<[CompetitionResultsDataPoint], Never> {
        switch competition.scoringModel {
        case .activityRingCloseCount, .rawNumbers, .percentOfGoals:
            let currentActivitySummaries = activitySummaryManager
                .activitySummaries(in: currentResult.dateInterval)
                .catchErrorJustReturn([])

            let previousActivitySummaries: AnyPublisher<[ActivitySummary]?, Never> = {
                guard let previousResult else { return .just(nil) }
                return activitySummaryManager
                    .activitySummaries(in: previousResult.dateInterval)
                    .map { $0 as [ActivitySummary]? }
                    .catchErrorJustReturn(nil)
                    .eraseToAnyPublisher()
            }()

            return Publishers
                .CombineLatest(currentActivitySummaries, previousActivitySummaries)
                .map { [weak self] currentActivitySummaries, previousActivitySummaries in
                    guard let strongSelf = self else { return [] }
                    let scoringModel = strongSelf.competition.scoringModel
                    let best = currentActivitySummaries
                        .sorted { $0.points(from: scoringModel) > $1.points(from: scoringModel) }
                        .first
                    return [
                        .activitySummaryBestDay(best),
                        .activitySummaryCloseCount(
                            current: currentActivitySummaries.filter(\.closed).count,
                            previous: previousActivitySummaries?.filter(\.closed).count
                        )
                    ]
                }
                .eraseToAnyPublisher()
        case .stepCount:
            let currentStepCounts = stepCountManager
                .stepCounts(in: currentResult.dateInterval)
                .catchErrorJustReturn([])

            let previousStepCounts: AnyPublisher<[StepCount]?, Never> = {
                guard let previousResult else { return .just(nil) }
                return stepCountManager.stepCounts(in: previousResult.dateInterval)
                    .map { $0 as [StepCount]? }
                    .catchErrorJustReturn([])
                    .eraseToAnyPublisher()
            }()

            return Publishers
                .CombineLatest(currentStepCounts, previousStepCounts)
                .map { currentStepCounts, _ in
                    let best = currentStepCounts
                        .sorted(by: \.count)
                        .last
                    guard let best else { return [] }
                    return [.stepCountBestDay(best)]
                }
                .eraseToAnyPublisher()
        case let .workout(type, metrics):
            let currentWorkouts = workoutManager
                .workouts(of: type, with: metrics, in: currentResult.dateInterval)
                .catchErrorJustReturn([])

            let previousWorkouts: AnyPublisher<[Workout]?, Never> = {
                guard let previousResult else { return .just(nil) }
                return workoutManager
                    .workouts(of: type, with: metrics, in: previousResult.dateInterval)
                    .map { $0 as [Workout]? }
                    .catchErrorJustReturn([])
                    .eraseToAnyPublisher()
            }()

            return Publishers
                .CombineLatest(currentWorkouts, previousWorkouts)
                .map { currentWorkouts, _ in
                    let best = currentWorkouts
                        .sorted { lhs, rhs in
                            let lhsPoints = lhs.points.map(\.value).reduce(0, +)
                            let rhsPoints = rhs.points.map(\.value).reduce(0, +)
                            return lhsPoints > rhsPoints
                        }
                        .first

                    guard let best else { return [] }
                    return [.workoutsBestDay(best)]
                }
                .eraseToAnyPublisher()
        }
    }
}
