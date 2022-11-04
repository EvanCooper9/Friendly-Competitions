import ECKit
import WidgetKit

struct FriendsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FriendsWidgetData {
        .preview
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FriendsWidgetData) -> Void) {
        guard !context.isPreview else {
            completion(.preview)
            return
        }
        
        let entry = FriendsWidgetData(name: "Someone")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FriendsWidgetData>) -> Void) {
        let entry = FriendsWidgetData(name: "Someone")
        let timeline = Timeline(entries: [entry], policy: .after(.now.advanced(by: 5.minutes)))
        completion(timeline)
    }
}
