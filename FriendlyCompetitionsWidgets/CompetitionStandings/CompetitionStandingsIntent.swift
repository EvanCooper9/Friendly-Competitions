import AppIntents
import ECNetworking
import Factory
import FCKit
import FirebaseAuth
import Foundation
import WidgetKit

struct CompetitionStandingsIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Competition"
    static var description = IntentDescription("Selects the competition do display information for.")

    @Parameter(title: "Competition")
    var competition: CompetitionParameter
}

struct CompetitionParameter: AppEntity, Identifiable {
    let id: String
    let name: String

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Competition"
    public static var defaultQuery = CompetitionParameterQuery()
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: name)
    }
}

struct CompetitionParameterQuery: EntityQuery {

    @Injected(\.network) private var network: Network

    func entities(for identifiers: [CompetitionParameter.ID]) async throws -> [CompetitionParameter] {
        guard let userID = Auth.auth().currentUser?.uid else { return [] }
        let request = CollectionRequest<Competition>(
            path: "competitions",
            filters: [.arrayContains(value: userID, property: "participants")]
        )
        let results = try await network.send(request)
        return results
            .filter { identifiers.contains($0.id) }
            .map { CompetitionParameter(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [CompetitionParameter] {
        guard let userID = Auth.auth().currentUser?.uid else { return [] }
        let request = CollectionRequest<Competition>(
            path: "competitions",
            filters: [.arrayContains(value: userID, property: "participants")]
        )
        let results = try await network.send(request)
        return results
            .map { CompetitionParameter(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> CompetitionParameter? {
        try? await suggestedEntities().first
    }
}

final class CompetitionStandingsProvider: AppIntentTimelineProvider {

    typealias Entry = CompetitionTimelineEntry
    typealias Intent = CompetitionStandingsIntent

    @Injected(\.network) private var network: Network

    func placeholder(in context: Context) -> CompetitionTimelineEntry {
        CompetitionTimelineEntry(data: .competition(.placeholder))
    }

    func snapshot(for configuration: CompetitionStandingsIntent, in context: Context) async -> CompetitionTimelineEntry {
        do {
            let basePath = "competitions/\(configuration.competition.id)"
            let competition = try await network.send(DocumentRequest<Competition>(path: basePath))
            let userStanding: Standing? = await {
                guard let userID = Auth.auth().currentUser?.uid else { return nil }
                return try? await network.send(DocumentRequest<Standing>(path: basePath + "/standings/" + userID))
            }()

            var rankRangeStart = 1
            var rankRangeEnd = 3

            if let userStanding {
                rankRangeStart = max(userStanding.rank - 1, 1)
                rankRangeEnd = rankRangeStart + 2
            }

            let standings = try await network.send(CollectionRequest<Standing>(path: "competitions/\(configuration.competition.id)/standings", filters: [
                .greaterThanOrEqualTo(value: rankRangeStart, property: "rank"),
                .lessThanOrEqualTo(value: rankRangeEnd, property: "rank")
            ]))

            var widgetStandings = [Int: WidgetStanding]()
            for standing in standings {
                guard !widgetStandings.keys.contains(standing.rank) || standing.userId == Auth.auth().currentUser?.uid else { continue }
                widgetStandings[standing.rank] = WidgetStanding(
                    rank: standing.rank,
                    points: standing.points,
                    highlight: standing.userId == Auth.auth().currentUser?.uid
                )
            }

            let data = WidgetCompetition(
                id: competition.id,
                name: competition.name,
                start: competition.start,
                end: competition.end,
                standings: widgetStandings.values
                    .sorted(by: \.points)
                    .reversed()
            )

            return CompetitionTimelineEntry(data: .competition(data))
        } catch {
            return CompetitionTimelineEntry(data: .error(error, .now))
        }
    }

    func timeline(for configuration: CompetitionStandingsIntent, in context: Context) async -> Timeline<CompetitionTimelineEntry> {
        let entry = await snapshot(for: configuration, in: context)
        let featureFlagManager = Container.shared.featureFlagManager.resolve()
        let updateInterval = featureFlagManager.value(forDouble: .widgetUpdateIntervalS).seconds
        return Timeline(entries: [entry], policy: .after(entry.date.addingTimeInterval(updateInterval)))
    }
}

struct CompetitionTimelineEntry: TimelineEntry {

    enum Data {
        case error(Error, Date)
        case competition(WidgetCompetition)

        var date: Date {
            switch self {
            case .error(_, let date): return date
            case .competition(let widgetCompetition): return widgetCompetition.createdOn
            }
        }
    }

    var date: Date { data.date }
    let data: Data

    var lastUpdated: String {
        date.formatted(date: date.isToday ? .omitted : .abbreviated, time: .shortened)
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
