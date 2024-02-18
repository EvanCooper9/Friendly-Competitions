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
        guard #available(iOS 17, *) else { return }
        WidgetCenter.shared.getCurrentConfigurations { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let widgetInfos):
                let competitionIDs = widgetInfos.compactMap { widgetInfo -> Competition.ID? in
                    guard let intent = widgetInfo.widgetConfigurationIntent(of: CompetitionStandingsIntent.self) else { return nil }
                    return intent.competition.id
                }
                subscribeToCompetitionStandingsWidgetData(for: competitionIDs)
            case .failure(let error):
                error.reportToCrashlytics()
            }
        }
    }

    private func subscribeToCompetitionStandingsWidgetData(for competitionIDs: [Competition.ID]) {
        competitionIDs
            .map { competitionID -> AnyPublisher<Competition?, Never> in
                competitionsManager.competitionPublisher(for: competitionID)
                    .map { $0 as Competition? }
                    .prepend(nil)
                    .catchErrorJustReturn(nil)
                    .eraseToAnyPublisher()
            }
            .combineLatest()
            .compactMapMany { $0 }
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
        competitionsManager.standing(for: competitionID, userID: userManager.user.id)
            .ignoreFailure()
            .flatMapLatest(withUnretained: self) { strongSelf, standing in
                let limit = max(standing.rank + 1, 3)
                return strongSelf.competitionsManager.standingsPublisher(for: competitionID, limit: limit)
                    .ignoreFailure()
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
