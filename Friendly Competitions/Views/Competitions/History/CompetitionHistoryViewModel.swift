import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class CompetitionHistoryViewModel: ObservableObject {

    // MARK: - Public Properties
    
    @Published private(set) var ranges = [CompetitionHistoryDateRange]()
    @Published private(set) var dataPoints = [CompetitionHistoryDataPoint]()
    @Published private(set) var loading = false
    
    var locked: Bool {
        ranges.first(where: { $0.selected })?.locked ?? true
    }

    // MARK: - Private Properties
    
    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.userManager) private var userManager

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(competition: Competition) {
        competitionsManager
            .history(for: competition.id)
            .ignoreFailure()
            .map { history in
                history
                    .enumerated()
                    .map { offset, event in
                        CompetitionHistoryDateRange(
                            start: event.start,
                            end: event.end,
                            selected: offset == 0,
                            locked: offset != 0
                        )
                    }
            }
            .assign(to: &$ranges)
        
        let standings = $ranges
            .filterMany(\.selected)
            .compactMap(\.first)
            .flatMapLatest(withUnretained: self) { strongSelf, dateRange -> AnyPublisher<[Competition.Standing], Never> in
                guard !dateRange.locked else { return .just([]) }
                return strongSelf.competitionsManager
                    .standings(for: competition.id, endingOn: dateRange.end)
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
            }
            .share(replay: 1)
        
        standings
            .combineLatest(userManager.userPublisher)
            .map { standings, user in
                var dataSets = [CompetitionHistoryDataPoint]()
                
                if let standing = standings.first(where: { $0.userId == user.id }) {
                    dataSets.append(.rank(standing.rank))
                    dataSets.append(.points(standing.points))
                }
                
                if let index = standings.firstIndex(where: { $0.userId == user.id }) {
                    let floor = Swift.max(0, index - 2)
                    let ceil = Swift.min(floor + 5, standings.count - 1)
                    dataSets.append(.standings(Array(standings[floor...ceil])))
                }
                
                return dataSets
            }
            .assign(to: &$dataPoints)
    }

    // MARK: - Public Methods
    
    func select(_ dateRange: CompetitionHistoryDateRange) {
        ranges = ranges.map { range in
            var range = range
            range.selected = range == dateRange
            return range
        }
    }
    
    func purchaseTapped() {
        
    }
}
