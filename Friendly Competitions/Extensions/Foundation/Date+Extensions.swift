import Foundation

extension Date {
    func addingTimeInterval(_ timeInterval: Int) -> Date {
        addingTimeInterval(TimeInterval(timeInterval))
    }

    var isToday: Bool {
        Calendar.current.isDate(self, equalTo: .now, toGranularity: .day)
    }

    func encodedToString(with formatter: DateFormatter = .dateDashed) -> String {
        formatter.string(from: self)
    }
}
