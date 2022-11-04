import ECKit
import WidgetKit

struct CompetitionsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CompetitionsWidgetData {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (CompetitionsWidgetData) -> ()) {
        guard !context.isPreview else {
            completion(.preview)
            return
        }
        
        let entry = CompetitionsWidgetData(competitions: [:])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CompetitionsWidgetData>) -> ()) {
        let entry = CompetitionsWidgetData.preview
        let timeline = Timeline(entries: [entry], policy: .after(.now.advanced(by: 5.minutes)))
        completion(timeline)
    }
}
