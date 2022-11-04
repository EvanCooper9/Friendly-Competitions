import SwiftUI
import WidgetKit

struct CompetitionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.evancooper.FriendlyCompetitions.Widgets.competitions",
            provider: CompetitionsWidgetProvider()
        ) { entry in
            CompetitionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Competitions")
        .description("Show your standings in active competitions")
    }
}

struct CompetitionsWidgetView: View {
    var entry: CompetitionsWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(entry.competitions.keys), id: \.self) { key in
                HStack {
                    Text(key)
                    Spacer()
                    Text(entry.competitions[key]!)
                        .bold()
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding()
    }
}

struct CompetitionsWidget_Previews: PreviewProvider {
    static var previews: some View {
        CompetitionsWidgetView(entry: .preview)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
