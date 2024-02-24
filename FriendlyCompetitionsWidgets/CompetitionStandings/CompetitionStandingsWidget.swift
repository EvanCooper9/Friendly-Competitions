import FCKit
import Firebase
import FirebaseAuth
import SwiftUI
import SwiftUIX
import WidgetKit

struct CompetitionStandingsWidget: Widget {
    let kind = WidgetIdentifier.competitionStandings.id()

    init() {
        FirebaseApp.configure()
        try? Auth.auth().useUserAccessGroup(AppGroup.id())
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CompetitionStandingsIntent.self, provider: CompetitionStandingsProvider()) { entry in
            CompetitionStandingsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Competition Standings")
        .description("View your standings in a competition at a glace")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

struct CompetitionStandingsWidgetView: View {

    let entry: CompetitionStandingsProvider.Entry

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        switch entry.data {
        case .competition(let competition):
            view(for: competition)
        case .error(let error, _):
            view(for: error)
        }
    }

    @ViewBuilder
    private func view(for competition: WidgetCompetition) -> some View {
        Group {
            switch widgetFamily {
            case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
                systemWidgetFamilyView(competition: competition)
            case .accessoryCircular, .accessoryInline, .accessoryRectangular:
                accessoryWidgetFamilyView(competition: competition)
            @unknown default:
                EmptyView()
            }
        }
        .widgetURL(URL(string: "https://friendly-competitions.app/competition/\(competition.id)"))
    }

    @ViewBuilder
    private func view(for error: Error) -> some View {
        switch widgetFamily {
        case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
            VStack {
                Text(error.localizedDescription)
                Label(entry.lastUpdated, systemImage: .arrowClockwise)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        case .accessoryCircular, .accessoryInline, .accessoryRectangular:
            Image(systemName: .exclamationmarkCircle)
                .resizable()
                .scaledToFit()
        @unknown default:
            EmptyView()
        }
    }

    private func systemWidgetFamilyView(competition: WidgetCompetition) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text(competition.name)
                        .multilineTextAlignment(.leading)

                    Text(competition.dateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 0) {
                Spacer()
                ForEach(competition.standings, id: \.id) { standing in
                    StandingRow(standing: standing)
                        .foregroundStyle(standing.highlight ? Color.accentColor : .secondary)
                }
                Spacer()
            }

            HStack {
                Label(entry.lastUpdated, systemImage: .arrowClockwise)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .cornerRadius(25 * 0.2237)
            }
        }
    }

    @ViewBuilder
    private func accessoryWidgetFamilyView(competition: WidgetCompetition) -> some View {
        let standing = competition.standings.highlighted
        if let standing {
            if widgetFamily == .accessoryCircular {
                VStack(spacing: 6) {
                    Text(standing.rank)
                    Divider()
                    Text(standing.points.formatted(.number.notation(.compactName)))
                }
            } else {
                Text([standing.rank, standing.points.formatted(.number.notation(.compactName))].joined(separator: " | "))
            }
        }
    }
}

struct StandingRow: View {

    let standing: WidgetStanding

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        HStack {
            Text(standing.rank)
                .monospaced()
            if standing.highlight {
                Image(systemName: .personFill)
            }

            Spacer()

            Text(standing.points.formatted(widgetFamily.showCompactPoints ? .number.notation(.compactName) : .number))
                .monospaced()
        }
        .font(.body)
        .lineLimit(1)
    }
}

private extension WidgetFamily {
    var showCompactPoints: Bool {
        switch self {
        case .systemSmall:
            return true
        default:
            return false
        }
    }
}

#if DEBUG
enum PreviewError: Error, LocalizedError {
    case test

    var errorDescription: String? {
        localizedDescription
    }

    var localizedDescription: String {
        switch self {
        case .test:
            return "Some test error"
        }
    }
}
//#Preview(as: .systemMedium) {
#Preview(as: .systemSmall) {
    CompetitionStandingsWidget()
} timeline: {
    CompetitionTimelineEntry(data: .error(PreviewError.test, .now))
}
#endif
