import Foundation

extension DateInterval {
    var end: Date { start.addingTimeInterval(duration) }
}
