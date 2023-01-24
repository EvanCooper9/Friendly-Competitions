import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class CompetitionResultsViewModel: ObservableObject {

    // MARK: - Public Properties
    
    @Published private(set) var ranges = [CompetitionResultsDateRange]()
    @Published private(set) var dataPoints = [CompetitionResultsDataPoint]()
    @Published private(set) var locked = false
    @Published private(set) var loading = false
    @Published var showPaywall = false

    // MARK: - Private Properties
    
    private let competition: Competition
    
    @Injected(Container.activitySummaryManager) private var activitySummaryManager
    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.premiumManager) private var premiumManager
    @Injected(Container.userManager) private var userManager
    @Injected(Container.workoutManager) private var workoutManager
    
    private let selectedIndex = CurrentValueSubject<Int, Never>(0)
    
    // MARK: - Lifecycle

    init(competition: Competition) {
        self.competition = competition
        
        let results = competitionsManager
            .results(for: competition.id)
            .catchErrorJustReturn([])
                
        Publishers
            .CombineLatest3(
                results,
                premiumManager.premium.map(\.isNil.not),
                selectedIndex
            )
            .map { results, hasPremium, selectedIndex in
                results
                    .sorted(by: \.end)
                    .reversed()
                    .enumerated()
                    .map { offset, result in
                        CompetitionResultsDateRange(
                            start: result.start,
                            end: result.end,
                            selected: offset == selectedIndex,
                            locked: offset == 0 ? false : !hasPremium
                        )
                    }
            }
            .receive(on: RunLoop.main)
            .assign(to: &$ranges)
        
        $ranges
            .map { $0.first(where: \.selected)?.locked ?? true }
            .assign(to: &$locked)
        
        let currentSelection = Publishers
            .CombineLatest(results, selectedIndex)
            .compactMap { results, selectedIndex -> (CompetitionResult, CompetitionResult?)? in
                if let previousIndex = selectedIndex <= results.count - 2 ? selectedIndex + 1 : nil {
                    return (results[selectedIndex], results[previousIndex])
                }
                return (results[selectedIndex], nil)
            }
            .handleEvents(withUnretained: self, receiveSubscription: { strongSelf, _ in strongSelf.loading = true })
        
        Publishers
            .CombineLatest(currentSelection, $locked)
            .flatMapLatest(withUnretained: self, { strongSelf, input in
                let (currentSelection, locked) = input
                guard !locked else { return .just([]) }
                return Publishers
                    .CombineLatest(
                        strongSelf.standingsDataPoints(currentResult: currentSelection.0, previousResult: currentSelection.1),
                        strongSelf.scoringDataPoints(currentResult: currentSelection.0, previousResult: currentSelection.1)
                    )
                    .first()
                    .map(+)
                    .isLoading { strongSelf.loading = $0 }
                    .eraseToAnyPublisher()
            })
            .receive(on: RunLoop.main)
            .assign(to: &$dataPoints)
    }

    // MARK: - Public Methods
    
    func select(_ dateRange: CompetitionResultsDateRange) {
        guard let index = ranges.firstIndex(of: dateRange) else { return }
        selectedIndex.send(index)
    }
    
    func purchaseTapped() {
        showPaywall.toggle()
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
        case .rawNumbers, .percentOfGoals:
            let previousActivitySummaries: AnyPublisher<[ActivitySummary]?, Never> = {
                guard let previousResult else { return .just(nil) }
                return activitySummaryManager
                    .activitySummaries(in: previousResult.dateInterval)
                    .map { $0 as [ActivitySummary]? }
                    .catchErrorJustReturn(nil)
                    .eraseToAnyPublisher()
            }()
            
            let currentActivitySummaries = activitySummaryManager
                .activitySummaries(in: currentResult.dateInterval)
                .catchErrorJustReturn([])

            return Publishers
                .CombineLatest(
                    currentActivitySummaries,
                    previousActivitySummaries
                )
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
        case let .workout(type, metrics):
            let previousWorkouts: AnyPublisher<[Workout]?, Error> = {
                guard let previousResult else { return .just(nil) }
                return workoutManager
                    .workouts(of: type, with: metrics, in: previousResult.dateInterval)
                    .map { $0 as [Workout]? }
                    .eraseToAnyPublisher()
            }()
            return Publishers
                .CombineLatest(
                    workoutManager.workouts(of: type, with: metrics, in: currentResult.dateInterval),
                    previousWorkouts
                )
                .ignoreFailure()
                .map { currentWorkouts, previousWorkouts in
                    let best = currentWorkouts
                        .sorted { lhs, rhs in
                            let lhsPoints = lhs.points.map(\.value).reduce(0, +)
                            let rhsPoints = rhs.points.map(\.value).reduce(0, +)
                            return lhsPoints > rhsPoints
                        }
                        .first
                    return [
                        .workoutsBestDay(best)
                    ]
                }
                .eraseToAnyPublisher()
        }
    }
}
