import FCKit
import Firebase
import FirebaseAuth
import SwiftUI
import SwiftUIX
import WidgetKit

struct CompetitionStandingsWidget: Widget {
    let kind = WidgetIdentifier.competitionStandings.rawValue

    init() {
        FirebaseApp.configure()
        try? Auth.auth().useUserAccessGroup(AppGroup.id)
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CompetitionStandingsIntent.self, provider: CompetitionStandingsProvider()) { entry in
            CompetitionStandingsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Competition Standings")
        .description("View your standings in a competition at a glace")
    }
}

struct CompetitionStandingsWidgetView: View {

    let entry: CompetitionStandingsProvider.Entry

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
                systemWidgetFamilyView
            case .accessoryCircular, .accessoryInline, .accessoryRectangular:
                accessoryWidgetFamilyView
            @unknown default:
                EmptyView()
            }
        }
        .widgetURL(URL(string: "https://friendly-competitions.app/competition/\(entry.competition.id)"))
    }

    private var systemWidgetFamilyView: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                VStack(alignment: .leading) {
                    Text(entry.competition.name)
                        .multilineTextAlignment(.leading)

                    Text(entry.competition.dateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if widgetFamily.showIcon {
                    Spacer()
                    Image("icon")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .cornerRadius(30 * 0.2237)
                }
            }

            Spacer()

            VStack(spacing: 0) {
                ForEach(entry.competition.standings, id: \.id) { standing in
                    StandingRow(standing: standing)
                        .foregroundStyle(standing.highlight ? Color.accentColor : .secondary)
                }
            }

            Spacer()

            Label(entry.lastUpdated, systemImage: .arrowClockwise)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var accessoryWidgetFamilyView: some View {
        let standing = entry.competition.standings.highlighted
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
    var showIcon: Bool {
        switch self {
        case .systemMedium, .systemLarge, .systemExtraLarge:
            return true
        default:
            return false
        }
    }
    var showCompactPoints: Bool {
        switch self {
        case .systemSmall:
            return true
        default:
            return false
        }
    }
}

//#Preview(as: .systemMedium) {
#Preview(as: .systemSmall) {
    CompetitionStandingsWidget()
} timeline: {
    CompetitionTimelineEntry(competition: .placeholder)
}
