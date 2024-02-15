import Charts
import ECKit
import Factory
import FCKit
import Firebase
import FirebaseAuth
import SwiftUI
import WidgetKit

struct CompetitionStandingsWidget: Widget {
    let kind = WidgetIdentifier.competitionStandings.rawValue

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CompetitionStandingsIntent.self, provider: CompetitionStandingsProvider()) { entry in
            CompetitionStandingsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Competition Standings")
        .description("View your standings in a competition at a glace")
    }
}

struct CompetitionStandingsWidgetView: View {

    let entry: CompetitionStandingsProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {

            Text(entry.competition.name)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.competition.dateString)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            ForEach(entry.competition.standings, id: \.id) { standing in
                StandingRow(standing: standing)
                    .foregroundStyle(standing.highlight ? Color.accentColor : .secondary)
            }

            Spacer()

            HStack {
                Image(systemName: .arrowClockwise)
                Text(entry.lastUpdated)
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
            .minimumScaleFactor(0.25)
        }
        .widgetURL(URL(string: "https://friendly-competitions.app/competition/\(entry.competition.id)"))
    }
}

struct StandingRow: View {

    let standing: WidgetStanding

    var body: some View {
        HStack {
            Text(standing.rank)
                .monospaced()
            if standing.highlight {
                Image(systemName: .personFill)
            }

            Spacer()

            Text("\(standing.points)")
                .monospaced()
        }
        .font(.body)
        .lineLimit(1)
    }
}

#Preview(as: .systemMedium) {
    CompetitionStandingsWidget()
} timeline: {
    CompetitionTimelineEntry(competition: .placeholder)
}
