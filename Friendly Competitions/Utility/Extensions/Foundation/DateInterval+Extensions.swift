import Foundation

extension DateInterval {
    static var dataFetchDefault: Self {
        DateInterval(start: .now.advanced(by: -2.days), end: .now)
    }
}
