import SwiftUI

struct CompetitionContainerDateRange: Equatable, Identifiable {

    // MARK: - Public Properties

    let start: Date
    let end: Date
    var selected: Bool
    let active: Bool
    let title: String

    var id: String { title }
    var dateInterval: DateInterval { .init(start: start, end: end) }

    init(start: Date, end: Date, selected: Bool = false, active: Bool = false) {
        self.start = start
        self.end = end
        self.selected = selected
        self.active = active
        self.title = Self.dateFormatter.string(from: start, to: end)
    }

    // MARK: - Private Properties

    private static let dateFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
