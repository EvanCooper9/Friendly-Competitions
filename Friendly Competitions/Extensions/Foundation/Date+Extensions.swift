import Foundation

extension Date {

    static var nowLocal: Date {
        Date.now.addingTimeInterval(NSTimeZone.default.secondsFromGMT(for: .now))
    }

    func addingTimeInterval(_ timeInterval: Int) -> Date {
        addingTimeInterval(TimeInterval(timeInterval))
    }

    var isToday: Bool {
        Calendar.current.isDate(self, equalTo: .now, toGranularity: .day)
    }

    func encodedToString(with formatter: DateFormatter = .full) -> String {
        formatter.string(from: self)
    }
}
