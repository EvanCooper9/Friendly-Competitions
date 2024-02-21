import Combine
import ECKit
import Factory
import WidgetKit

// sourcery: AutoMockable
public protocol WidgetDataManaging {
    func competitions(userID: String?) async -> [(id: String, name: String)]
    func data(for competitionID: String, userID: String?) -> AnyPublisher<WidgetCompetition, Never>
}

final class WidgetDataManager: WidgetDataManaging {

    @LazyInjected(\.database) private var database: Database
    @LazyInjected(\.widgetStore) private var widgetStore: WidgetStore

    private var cancellables = Cancellables()

    init() {
//        subscribeToCompetitions()

//        let competitionIDs = widgetStore.configurations
//            .filter { _, lastUpdated in lastUpdated.timeIntervalSince(.now.addingTimeInterval(-1.days)) < 1.days }
//            .keys
//        subscribeToCompetitionStandingsWidgetData(for: Array(competitionIDs))
    }

    func competitions(userID: String?) async -> [(id: String, name: String)] {
        guard let userID else { return [] }
        return await withCheckedContinuation { continuation in
            database.collection("competitions")
                .filter(.arrayContains(value: userID), on: "participants")
                .getDocuments(ofType: Competition.self)
                .catchErrorJustReturn([])
                .mapMany { competition in
                    (id: competition.id, name: competition.name)
                }
                .sink { results in
                    continuation.resume(returning: results)
                }
                .store(in: &cancellables)
        }
    }

    func data(for competitionID: String, userID: String?) -> AnyPublisher<WidgetCompetition, Never> {
        database.document("competitions/\(competitionID)")
            .get(as: Competition.self)
            .reportErrorToCrashlytics()
            .ignoreFailure()
            .flatMapLatest { competition in
                self.standings(for: competitionID, userID: userID)
                    .map { (competition, $0) }
                    .eraseToAnyPublisher()
            }
            .map { (competition: Competition, standings: [WidgetStanding]) in
                WidgetCompetition(
                    id: competition.id,
                    name: competition.name,
                    start: competition.start,
                    end: competition.end,
                    standings: standings
                )
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

//    private func subscribeToCompetitions() {
//        competitionsManager.competitions
//            .map { [weak self] competitions -> AnyPublisher<[String: WidgetCompetition], Never> in
//                guard let self else { return .never() }
//                return competitions
//                    .map { competition in
//                        data(for: competition.id)
//                            .map { (competition.id, $0) }
//                    }
//                    .combineLatest()
//                    .map { resuls in
//                        Dictionary(uniqueKeysWithValues: results)
//                    }
//            }
//            .sink(withUnretained: self) { $0.widgetStore.competitions = $1 }
//            .store(in: &cancellables)
//    }

    private func standings(for competitionID: String, userID: String?) -> AnyPublisher<[WidgetStanding], Never> {
        var userStanding: AnyPublisher<Standing?, Never> = .just(nil)
        if let userID {
            userStanding = database.document("competitions/\(competitionID)/standings/\(userID)")
                .get(as: Standing.self)
                .asOptional()
                .catchErrorJustReturn(nil)
                .eraseToAnyPublisher()
        }

        return userStanding
            .flatMapLatest(withUnretained: self) { strongSelf, standing in
                var rankRangeStart = 1
                var rankRangeEnd = 3

                if let standing {
                    rankRangeStart = max(standing.rank - 1, 1)
                    rankRangeEnd = rankRangeStart + 2
                }

                return strongSelf.database.collection("competitions/\(competitionID)/standings")
                    .filter(.greaterThanOrEqualTo(value: rankRangeStart), on: "rank")
                    .filter(.lessThanOrEqualTo(value: rankRangeEnd), on: "rank")
                    .getDocuments(ofType: Standing.self)
                    .catchErrorJustReturn([])
            }
            .map { standings in
                var widgetStandings = [Int: WidgetStanding]()
                for standing in standings {
                    guard !widgetStandings.keys.contains(standing.rank) || standing.userId == userID else { continue }
                    widgetStandings[standing.rank] = WidgetStanding(
                        rank: standing.rank,
                        points: standing.points,
                        highlight: standing.userId == userID
                    )
                }

                return widgetStandings
                    .values
                    .sorted(by: \.rank)
            }
            .eraseToAnyPublisher()
    }
}

fileprivate struct Competition: Decodable {
    let id: String
    let name: String
    let start: Date
    let end: Date
}

fileprivate struct Standing: Decodable {
    let userId: String
    let rank: Int
    let points: Int
}
