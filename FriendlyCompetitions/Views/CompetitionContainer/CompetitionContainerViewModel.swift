import Algorithms
import FCKit
import Combine
import CombineExt
import ECKit
import Factory

final class CompetitionContainerViewModel: ObservableObject {

    enum Content {
        case current
        case result(current: CompetitionResult, previous: CompetitionResult?)
    }

    // MARK: - Public Properties

    let competition: Competition
    @Published private(set) var dateRanges: [CompetitionContainerDateRange]
    @Published private(set) var content = Content.current

    // MARK: - Private Properties

    @Injected(\.competitionsManager) private var competitionsManager: CompetitionsManaging
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging

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

        Publishers
            .CombineLatest(results, selectedDateRangeIndex)
            .map { results, selectedIndex in
                let resultsDateRanges = results.map { result in
                    CompetitionContainerDateRange(start: result.start, end: result.end)
                }

                let allDateRanges = ([currentDateRange] + resultsDateRanges).uniqued { $0.title }

                return allDateRanges.enumerated().map { index, dateRange in
                    var dateRange = dateRange
                    dateRange.selected = index == selectedIndex
                    return dateRange
                }
            }
            .assign(to: &$dateRanges)

        Publishers
            .CombineLatest3($dateRanges, selectedDateRangeIndex, results)
            .compactMap { dateRanges, selectedIndex, results -> Content? in

                let selectedResult: CompetitionResult? = {
                    let resultsIndex = competition.isActive ? selectedIndex - 1 : selectedIndex
                    guard resultsIndex >= 0, resultsIndex < results.count else { return nil }
                    return results[resultsIndex]
                }()

                let previousResult: CompetitionResult? = {
                    let resultsIndex = (competition.isActive ? selectedIndex - 1 : selectedIndex) + 1
                    guard resultsIndex >= 0, resultsIndex < results.count else { return nil }
                    return results[resultsIndex]
                }()

                guard let dateRange = dateRanges.first(where: \.selected) else { return nil }
                if dateRange.id == currentDateRange.id {
                    return .current
                } else if let selectedResult {
                    return .result(current: selectedResult, previous: previousResult)
                } else {
                    return nil
                }
            }
            .assign(to: &$content)
    }

    // MARK: - Public Methods

    func select(dateRange: CompetitionContainerDateRange) {
        guard let index = dateRanges.firstIndex(of: dateRange) else { return }
        selectedDateRangeIndex.send(index)
    }
}
