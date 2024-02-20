import Foundation

public enum DateToStartOfDay: PostDecodingStrategy {
    public static func transform(_ value: Date) -> Date { value }
}
