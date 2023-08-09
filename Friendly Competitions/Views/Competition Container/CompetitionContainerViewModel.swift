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

        let activeDateRange = CompetitionContainerDateRange(start: competition.start, end: competition.end, selected: false, locked: false)
        if competition.isActive {
            // showing current standings
            dateRanges = [activeDateRange]
        } else {
            // showing results only
            dateRanges = []
        }

        let results = competitionsManager.results(for: competition.id).catchErrorJustReturn([])

        Publishers
            .CombineLatest3(
                results,
                selectedDateRangeIndex,
                premiumManager.premium.map(\.isNil.not)
            )
            .map { results, selectedIndex, hasPremium in
                let resultsDateRanges = results.enumerated().map { index, result in
                    CompetitionContainerDateRange(start: result.start,
                                                  end: result.end,
                                                  selected: false,
                                                  locked: !hasPremium && index > 0)
                }

                let allDateRanges: [CompetitionContainerDateRange]
                if competition.isActive {
                    allDateRanges = [activeDateRange].appending(contentsOf: resultsDateRanges)
                } else {
                    allDateRanges = resultsDateRanges
                }

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
                guard selectedIndex < results.count else { return nil }
                if competition.isActive {
                    guard selectedIndex > 0 else { return nil } // make sure current not selected
                    return results[selectedIndex - 1] // active standings are prepended
                } else {
                    return results[selectedIndex]
                }
            }
            .unwrap()

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
            .compactMap { dateRanges, selectedResult, previousResult in
                guard let dateRange = dateRanges.first(where: \.selected) else { return nil }
                if dateRange.id == activeDateRange.id {
                    return .current
                } else if dateRange.locked {
                    return .locked
                } else {
                    return .result(current: selectedResult, previous: previousResult)
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
