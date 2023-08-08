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
    @Injected(\.premiumManager) private var premiumManager

    private let selectedDateRangeIndex = CurrentValueSubject<Int, Never>(0)

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(competition: Competition) {
        self.competition = competition

        let currentCompetitionContainerDateRange = CompetitionContainerDateRange(start: competition.start, end: competition.end, selected: false, locked: false)
        dateRanges = [currentCompetitionContainerDateRange]

        let results = competitionsManager.results(for: competition.id).catchErrorJustReturn([])

        Publishers
            .CombineLatest3(
                results,
                selectedDateRangeIndex,
                premiumManager.premium.map(\.isNil.not)
            )
            .map { results, selectedIndex, hasPremium in
                let resultDateRanges = results.enumerated().map { index, result in
                    CompetitionContainerDateRange(start: result.start,
                                         end: result.end,
                                         selected: false,
                                         locked: !hasPremium && index > 0)
                }

                let allDateRanges = [currentCompetitionContainerDateRange].appending(contentsOf: resultDateRanges)

                return allDateRanges.enumerated().map { index, dateRange in
                    var dateRange = dateRange
                    dateRange.selected = index == selectedIndex
                    return dateRange
                }
            }
            .prepend([currentCompetitionContainerDateRange])
            .assign(to: &$dateRanges)

        let selectedResult = Publishers
            .CombineLatest(selectedDateRangeIndex, results)
            .map { selectedIndex, results -> CompetitionResult? in
                guard selectedIndex > 0, selectedIndex < results.count else { return nil } // make sure current not selected
                return results[selectedIndex - 1]
            }

        let previousResult = Publishers
            .CombineLatest(selectedDateRangeIndex, results)
            .map { selectedIndex, results -> CompetitionResult? in
                let previousResultIndex = selectedIndex + 1
                guard previousResultIndex < results.count else { return nil }
                return results[previousResultIndex]
            }

        Publishers
            .CombineLatest3(
                $dateRanges,
                selectedResult,
                previousResult
            )
            .compactMap { dateRanges, selectedResult, previousResult -> Content? in
                guard let dateRange = dateRanges.first(where: \.selected) else { return nil }
                if dateRange.id == currentCompetitionContainerDateRange.id {
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
