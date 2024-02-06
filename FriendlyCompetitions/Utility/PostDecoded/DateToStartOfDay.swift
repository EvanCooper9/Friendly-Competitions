import Foundation

enum DateToStartOfDay: PostDecodingStrategy {
    static func transform(_ value: Date) -> Date { value }
}
