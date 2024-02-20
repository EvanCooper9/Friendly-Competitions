import AppIntents
import Combine
import ECKit
import Factory
import FCKit
import FirebaseAuth
import Foundation
import SwiftUI
import SwiftUIX
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

    @Injected(\.widgetDataManager) private var widgetDataManager: WidgetDataManaging

    func entities(for identifiers: [CompetitionParameter.ID]) async throws -> [CompetitionParameter] {
        let results = await widgetDataManager.competitions(userID: Auth.auth().currentUser?.uid)
        return results
            .filter { identifiers.contains($0.id) }
            .map(CompetitionParameter.init)
    }

    func suggestedEntities() async throws -> [CompetitionParameter] {
        let results = await widgetDataManager.competitions(userID: Auth.auth().currentUser?.uid)
        return results.map(CompetitionParameter.init)
    }

    func defaultResult() async -> CompetitionParameter? {
        try? await suggestedEntities().first
    }
}

final class CompetitionStandingsProvider: AppIntentTimelineProvider {

    typealias Entry = CompetitionTimelineEntry
    typealias Intent = CompetitionStandingsIntent

    @Injected(\.database) private var database: Database
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging
    @Injected(\.widgetDataManager) private var widgetDataManager: WidgetDataManaging
    @Injected(\.widgetStore) private var widgetStore: WidgetStore

    private var cancellables = Cancellables()

    func placeholder(in context: Context) -> CompetitionTimelineEntry {
        CompetitionTimelineEntry(competition: .placeholder)
    }

    func snapshot(for configuration: CompetitionStandingsIntent, in context: Context) async -> CompetitionTimelineEntry {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else { return }
            widgetDataManager.data(for: configuration.competition.id, userID: Auth.auth().currentUser?.uid)
                .sink(receiveValue: { competition in
                    let entry = CompetitionTimelineEntry(competition: competition)
                    continuation.resume(returning: entry)
                })
                .store(in: &cancellables)
        }
    }

    func timeline(for configuration: CompetitionStandingsIntent, in context: Context) async -> Timeline<CompetitionTimelineEntry> {
        let entry = await snapshot(for: configuration, in: context)
        let updateInterval = featureFlagManager.value(forDouble: .widgetUpdateIntervalS).seconds
        return Timeline(entries: [entry], policy: .after(entry.date.addingTimeInterval(updateInterval)))
    }
}

struct CompetitionTimelineEntry: TimelineEntry {
    var date: Date { competition.createdOn }
    let competition: WidgetCompetition

    var lastUpdated: String {
        date.formatted(date: date.isToday ? .omitted : .abbreviated, time: .complete)
    }
}
