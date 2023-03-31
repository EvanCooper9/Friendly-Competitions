import Foundation

enum DateToEndOfDay: PostDecodingStrategy {
    static func transform(_ value: Date) -> Date {
        Calendar.current.startOfDay(for: value).advanced(by: 23.hours + 59.minutes + 59.seconds)
    }
}
