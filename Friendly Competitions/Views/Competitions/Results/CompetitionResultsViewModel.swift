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
    @Injected(Container.storeKitManager) private var storeKitManager
    @Injected(Container.userManager) private var userManager
    @Injected(Container.workoutManager) private var workoutManager
    
    private let selectedIndex = CurrentValueSubject<Int, Never>(0)
    
    // MARK: - Lifecycle

    init(competition: Competition) {
        self.competition = competition
                
        Publishers
            .CombineLatest3(
                competitionsManager.results(for: competition.id).catchErrorJustReturn([]),
                storeKitManager.premium.map(\.isNil.not),
                selectedIndex
            )
            .map { results, hasPremium, selectedIndex in
                results
                    .sorted(by: \.end)
                    .reversed()
                    .enumerated()
                    .map { offset, event in
                        CompetitionResultsDateRange(
                            start: event.start,
                            end: event.end,
                            selected: offset == selectedIndex,
                            locked: offset == 0 ? false : !hasPremium
                        )
                    }
            }
            .receive(on: RunLoop.main)
            .assign(to: &$ranges)
        
        let currentRanges = $ranges
            .compactMap { ranges -> (CompetitionResultsDateRange, CompetitionResultsDateRange?)?  in
                guard let currentIndex = ranges.firstIndex(where: \.selected) else { return nil }
                if let previousIndex = currentIndex <= ranges.count - 2 ? currentIndex + 1 : nil {
                    return (ranges[currentIndex], ranges[previousIndex])
                }
                return (ranges[currentIndex], nil)
            }
            .share(replay: 1)
        
        currentRanges
            .map(\.0.locked)
            .assign(to: &$locked)
        
        currentRanges
            .filter { !$0.0.locked }
            .flatMapLatest(withUnretained: self) { strongSelf, ranges in
                Publishers
                    .CombineLatest(
                        strongSelf.standingsDataPoints(currentRange: ranges.0, previousRange: ranges.1),
                        strongSelf.scoringDataPoints(currentRange: ranges.0, previousRange: ranges.1)
                    )
                    .first()
                    .map(+)
                    .isLoading { strongSelf.loading = $0 }
                    .eraseToAnyPublisher()
            }
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
    
    private func standingsDataPoints(currentRange: CompetitionResultsDateRange, previousRange: CompetitionResultsDateRange?) -> AnyPublisher<[CompetitionResultsDataPoint], Never> {
        let previousStandings: AnyPublisher<[Competition.Standing]?, Never> = {
            guard let previousRange else { return .just(nil) }
            return competitionsManager
                .standings(for: competition.id, endingOn: previousRange.dateInterval.end)
                .map { $0 as [Competition.Standing]? }
                .catchErrorJustReturn(nil)
                .eraseToAnyPublisher()
        }()
        
        let currentStandings = competitionsManager
            .standings(for: competition.id, endingOn: currentRange.end)
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
    
    private func scoringDataPoints(currentRange: CompetitionResultsDateRange, previousRange: CompetitionResultsDateRange?) -> AnyPublisher<[CompetitionResultsDataPoint], Never> {
        switch competition.scoringModel {
        case .rawNumbers, .percentOfGoals:
            let previousActivitySummaries: AnyPublisher<[ActivitySummary]?, Never> = {
                guard let previousRange else { return .just(nil) }
                return activitySummaryManager
                    .activitySummaries(in: previousRange.dateInterval)
                    .map { $0 as [ActivitySummary]? }
                    .catchErrorJustReturn(nil)
                    .eraseToAnyPublisher()
            }()
            
            let currentActivitySummaries = activitySummaryManager
                .activitySummaries(in: currentRange.dateInterval)
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
                guard let previousRange else { return .just(nil) }
                return workoutManager
                    .workouts(of: type, with: metrics, in: previousRange.dateInterval)
                    .map { $0 as [Workout]? }
                    .eraseToAnyPublisher()
            }()
            return Publishers
                .CombineLatest(
                    workoutManager.workouts(of: type, with: metrics, in: currentRange.dateInterval),
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
