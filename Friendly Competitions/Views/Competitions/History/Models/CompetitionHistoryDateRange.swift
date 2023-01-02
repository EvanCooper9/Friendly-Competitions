import SwiftUI

struct CompetitionHistoryDateRange: Equatable {
    
    // MARK: - Public Properties
    
    let start: Date
    let end: Date
    var selected: Bool
    var locked: Bool
    
    lazy var title: String = {
        Self.dateFormatter.string(from: start, to: end)
    }()
    
    // MARK: - Private Properties
    
    private static let dateFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
