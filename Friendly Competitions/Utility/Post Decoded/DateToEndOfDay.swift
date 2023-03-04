import Foundation

enum DateToEndOfDay: PostDecodingStrategy {
    static func transform(_ value: Date) -> Date { value.advanced(by: 23.hours + 59.minutes) }
}
