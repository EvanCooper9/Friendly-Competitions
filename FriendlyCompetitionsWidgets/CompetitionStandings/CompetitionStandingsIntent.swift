import AppIntents
import FCKit
import Factory
import Foundation
import SwiftUI
import SwiftUIX
import WidgetKit

@available(iOS, introduced: 17)
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

    @Injected(\.widgetStore) private var widgetStore: WidgetStore

    func entities(for identifiers: [CompetitionParameter.ID]) async throws -> [CompetitionParameter] {
        widgetStore.competitions
            .filter { identifiers.contains($0.id) }
            .map { competition in
                CompetitionParameter(id: competition.id, name: competition.name)
            }
    }

    func suggestedEntities() async throws -> [CompetitionParameter] {
        widgetStore.competitions.map { competition in
            CompetitionParameter(id: competition.id, name: competition.name)
        }
    }

    func defaultResult() async -> CompetitionParameter? {
        try? await suggestedEntities().first
    }
}

@available(iOS, introduced: 17)
struct CompetitionStandingsProvider: AppIntentTimelineProvider {

    typealias Entry = CompetitionTimelineEntry
    typealias Intent = CompetitionStandingsIntent

    @Injected(\.widgetStore) private var widgetStore: WidgetStore

    func placeholder(in context: Context) -> CompetitionTimelineEntry {
        let competition = WidgetCompetition(
            id: "placeholder",
            name: "Placeholder",
            start: .now,
            end: .distantFuture,
            standings: [
                WidgetStanding(rank: 1, points: 2_345, highlight: false),
                WidgetStanding(rank: 2, points: 1_234, highlight: false),
                WidgetStanding(rank: 3, points: 987, highlight: false),
            ]
        )
        return .init(competition: competition)
    }

    func snapshot(for configuration: CompetitionStandingsIntent, in context: Context) async -> CompetitionTimelineEntry {
        let competition = widgetStore.competitions.first { competition in
            competition.id == configuration.competition.id
        }
        return CompetitionTimelineEntry(competition: competition ?? .placeholder)
    }

    func timeline(for configuration: CompetitionStandingsIntent, in context: Context) async -> Timeline<CompetitionTimelineEntry> {
        let entry = await snapshot(for: configuration, in: context)
        return Timeline(entries: [entry], policy: .after(entry.date.addingTimeInterval(15.minutes)))
    }
}

struct CompetitionTimelineEntry: TimelineEntry {
    var date: Date { competition.createdOn }
    let competition: WidgetCompetition

    var lastUpdated: String {
        date.formatted(date: date.isToday ? .omitted : .abbreviated, time:  .shortened)
    }
}
