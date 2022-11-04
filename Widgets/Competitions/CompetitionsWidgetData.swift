import WidgetKit

struct CompetitionsWidgetData: TimelineEntry {
    let date: Date = .now
    let competitions: [String: String]
}

extension CompetitionsWidgetData {
    static var preview: Self {
        .init(competitions: [
            "Weekly": "\(Int.random(in: 1...10))",
            "Monthly": "\(Int.random(in: 1...10))",
            "Work": "\(Int.random(in: 1...10))"
        ])
    }
}
