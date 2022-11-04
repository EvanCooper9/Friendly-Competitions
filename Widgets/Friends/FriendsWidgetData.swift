import WidgetKit

struct FriendsWidgetData: TimelineEntry {
    let date: Date = .now
    let name: String
}

extension FriendsWidgetData {
    static var preview: Self {
        .init(name: "Evan")
    }
}
