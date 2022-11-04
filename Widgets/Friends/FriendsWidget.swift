import SwiftUI
import WidgetKit

struct FriendsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.evancooper.FriendlyCompetitions.Widgets.friends",
            provider: FriendsWidgetProvider()
        ) { entry in
            FriendsWidgetView(entry: entry)
        }
        .configurationDisplayName("Friends")
        .description("Show activity summaries of your friends")
    }
}

struct FriendsWidgetView: View {
    
    let entry: FriendsWidgetData
    
    var body: some View {
        Text("Friends")
    }
}

struct FriendsWidget_Previews: PreviewProvider {
    static var previews: some View {
        FriendsWidgetView(entry: .preview)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
