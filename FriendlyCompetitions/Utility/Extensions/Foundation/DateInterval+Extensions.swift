import Foundation

extension DateInterval {
    static var dataFetchDefault: Self {
        let start = Calendar.current.startOfDay(for: .now).addingTimeInterval(-2.days)
        return DateInterval(start: start, end: .now)
    }
}

extension DateInterval {
    func combined(with other: DateInterval) -> DateInterval {
        let minStart = min(start, other.start)
        let maxEnd = max(end, other.end)
        return .init(start: minStart, end: maxEnd)
    }
}
