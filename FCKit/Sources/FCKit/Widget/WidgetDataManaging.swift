import Combine
import ECKit
import Factory
import WidgetKit

// sourcery: AutoMockable
public protocol WidgetDataManaging {
    func competitions(userID: String?) async -> [(id: String, name: String)]
    func data(for competitionID: String, userID: String?) async -> WidgetCompetition
}

final class WidgetDataManager: WidgetDataManaging {

    @LazyInjected(\.database) private var database: Database

    private var cancellables = Cancellables()

    func competitions(userID: String?) async -> [(id: String, name: String)] {
        guard let userID else { return [] }
        return await withCheckedContinuation { continuation in
            database.collection("competitions")
                .filter(.arrayContains(value: userID), on: "participants")
                .getDocuments(ofType: Competition.self)
//                .reportErrorToCrashlytics()
                .catchErrorJustReturn([])
                .mapMany { (id: $0.id, name: $0.name) }
                .sink { continuation.resume(returning: $0) }
                .store(in: &cancellables)
        }
    }

    func data(for competitionID: String, userID: String?) async -> WidgetCompetition {
        await withCheckedContinuation { continuation in
            database.document("competitions/\(competitionID)")
                .get(as: Competition.self, source: .cacheFirst)
//                .reportErrorToCrashlytics()
                .print("DEBUGGING widget data \(#line)")
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
                .print("DEBUGGING widget data \(#line)")
                .sink { continuation.resume(returning: $0) }
                .store(in: &cancellables)
        }
    }

    // MARK: - Private

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
            .print("DEBUGGING user standing")
            .flatMapLatest { standing in
                var rankRangeStart = 1
                var rankRangeEnd = 3

                if let standing {
                    rankRangeStart = max(standing.rank - 1, 1)
                    rankRangeEnd = rankRangeStart + 2
                }

                return self.database.collection("competitions/\(competitionID)/standings")
                    .filter(.greaterThanOrEqualTo(value: rankRangeStart), on: "rank")
                    .filter(.lessThanOrEqualTo(value: rankRangeEnd), on: "rank")
                    .getDocuments(ofType: Standing.self)
                    .catchErrorJustReturn([])
            }
            .print("DEBUGGING standings")
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
            .print("DEBUGGING widget standings")
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
