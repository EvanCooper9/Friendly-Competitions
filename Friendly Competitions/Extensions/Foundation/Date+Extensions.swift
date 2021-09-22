import Foundation

extension Date {

    static var nowLocal: Date {
        Date.now.addingTimeInterval(NSTimeZone.default.secondsFromGMT(for: .now))
    }

    func addingTimeInterval(_ timeInterval: Int) -> Date {
        addingTimeInterval(TimeInterval(timeInterval))
    }

    var isToday: Bool {
        Calendar.current.compare(self, to: .nowLocal, toGranularity: .day) == .orderedSame
    }

    func encodedToString(with formatter: DateFormatter = .full) -> String {
        formatter.string(from: self)
    }
}
