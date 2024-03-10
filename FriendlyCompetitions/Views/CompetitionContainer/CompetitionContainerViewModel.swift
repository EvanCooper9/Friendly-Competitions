import Algorithms
import Combine
import CombineExt
import ECKit
import Factory

final class CompetitionContainerViewModel: ObservableObject {

    enum Content {
        case current
        case result(current: CompetitionResult, previous: CompetitionResult?)
        case locked
    }

    // MARK: - Public Properties

    let competition: Competition
    @Published private(set) var dateRanges: [CompetitionContainerDateRange]
    @Published private(set) var content = Content.current

    // MARK: - Private Properties

    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.featureFlagManager) private var featureFlagManager
    @LazyInjected(\.premiumManager) private var premiumManager

    private let selectedDateRangeIndex = CurrentValueSubject<Int, Never>(0)

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(competition: Competition, result: CompetitionResult?) {
        self.competition = competition

        let currentDateRange = CompetitionContainerDateRange(start: competition.start, end: competition.end, active: true)
        dateRanges = [currentDateRange]

        if let result {
            let resultDateRange = CompetitionContainerDateRange(start: result.start, end: result.end)
            dateRanges.append(resultDateRange)
            selectedDateRangeIndex.send(dateRanges.count - 1)
        }

        let results = competitionsManager.results(for: competition.id)
            .prepend(Array([result].compacted()))
            .catchErrorJustReturn([])

        let blockedByPremium: AnyPublisher<Bool, Never> = {
            if featureFlagManager.value(forBool: .premiumEnabled) {
                return premiumManager.premium
                    .map(\.isNil)
                    .eraseToAnyPublisher()
            } else {
                return .just(false)
            }
        }()

        Publishers
            .CombineLatest3(
                results,
                selectedDateRangeIndex,
                blockedByPremium
            )
            .map { results, selectedIndex, blockedByPremium in
                let resultsDateRanges = results.enumerated()
                    .map { index, result in
                        CompetitionContainerDateRange(start: result.start,
                                                      end: result.end,
                                                      locked: index > 0 && blockedByPremium)
                    }

                let allDateRanges = ([currentDateRange] + resultsDateRanges).uniqued { $0.title }

                return allDateRanges.enumerated().map { index, dateRange in
                    var dateRange = dateRange
                    dateRange.selected = index == selectedIndex
                    return dateRange
                }
            }
            .assign(to: &$dateRanges)

        let selectedResult = Publishers
            .CombineLatest(selectedDateRangeIndex, results)
            .map { selectedIndex, results -> CompetitionResult? in
                let resultsIndex = competition.isActive ? selectedIndex - 1 : selectedIndex
                guard resultsIndex >= 0, resultsIndex < results.count else { return nil }
                return results[resultsIndex]
            }

        let previousResult = Publishers
            .CombineLatest(selectedDateRangeIndex, results)
            .map { selectedIndex, results -> CompetitionResult? in
                let resultsIndex = (competition.isActive ? selectedIndex - 1 : selectedIndex) + 1
                guard resultsIndex >= 0, resultsIndex < results.count else { return nil }
                return results[resultsIndex]
            }

        Publishers
            .CombineLatest3(
                $dateRanges,
                selectedResult,
                previousResult
            )
            .compactMap { dateRanges, selectedResult, previousResult in
                guard let dateRange = dateRanges.first(where: \.selected) else { return nil }
                if dateRange.id == currentDateRange.id {
                    return .current
                } else if dateRange.locked {
                    return .locked
                } else if let selectedResult {
                    return .result(current: selectedResult, previous: previousResult)
                } else {
                    return nil
                }
            }
            .unwrap()
            .assign(to: &$content)
    }

    // MARK: - Public Methods

    func select(dateRange: CompetitionContainerDateRange) {
        guard let index = dateRanges.firstIndex(of: dateRange) else { return }
        selectedDateRangeIndex.send(index)
    }
}
