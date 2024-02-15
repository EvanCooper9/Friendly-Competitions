import Combine
import ECKit
import Factory
import WidgetKit

// sourcery: AutoMockable
protocol WidgetDataManaging {}

final class WidgetDataManager: WidgetDataManaging {

    @Injected(\.competitionsManager) private var competitionsManager: CompetitionsManaging
    @Injected(\.searchManager) private var searchManager: SearchManaging
    @Injected(\.userManager) private var userManager: UserManaging
    @Injected(\.widgetStore) private var widgetStore: WidgetStore

    private var cancellables = Cancellables()

    init() {
        subscribeToWidgetData()
    }

    private func subscribeToWidgetData() {
        competitionsManager.competitions
            .flatMapLatest(withUnretained: self) { strongSelf, competitions in
                competitions.map { competition in
                    strongSelf
                        .standings(for: competition.id)
                        .map { (competition, $0) }
                }
                .combineLatest()
            }
            .map { results in
                results.map { competition, standings in
                    WidgetCompetition(
                        id: competition.id,
                        name: competition.name,
                        start: competition.start,
                        end: competition.end,
                        standings: standings
                    )
                }
            }
            .sink(withUnretained: self) { strongSelf, competitions in
                strongSelf.widgetStore.competitions = competitions
                WidgetCenter.shared.reloadAllTimelines()
            }
            .store(in: &cancellables)
    }

    private func standings(for competitionID: Competition.ID) -> AnyPublisher<[WidgetStanding], Never> {
        competitionsManager
            .standingsPublisher(for: competitionID)
            .catchErrorJustReturn([])
            .map { [weak self] standings -> [Competition.Standing] in
                guard let self else { return [] }
                let standings = standings.sorted(by: \.rank)
                let userID = userManager.user.id

                guard let standingIndex = standings.firstIndex(where: { $0.id == userID }), standingIndex > 0 else {
                    return Array(standings.prefix(3))
                }
                if standingIndex == standings.count - 1 {
                    return Array(standings.suffix(3))
                } else {
                    return Array(standings[(standingIndex - 1)...(standingIndex + 1)])
                }
            }
            .map { [weak self] standings in
                standings.map { standing in
                    WidgetStanding(
                        rank: standing.rank,
                        points: standing.points,
                        highlight: self?.userManager.user.id == standing.id
                    )
                }
            }
            .eraseToAnyPublisher()
    }
}
