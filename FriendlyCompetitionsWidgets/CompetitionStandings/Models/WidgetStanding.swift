import AppIntents
import Factory
import Foundation
import WidgetKit

extension NumberFormatter {
    static var ordinal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()
}

public struct WidgetStanding: Codable {
    public init(rank: Int, points: Int, highlight: Bool) {
        self.id = UUID()
        self.rank = NumberFormatter.ordinal.string(from: NSNumber(value: rank)) ?? "\(rank)"
        self.points = points
        self.highlight = highlight
    }

    public let id: UUID
    public let rank: String
    public let points: Int
    public let highlight: Bool

    let pointsHistory: [Int] = stride(from: 0, to: 100, by: 10).map { $0 + Int.random(in: 0...9) }
    let rankHistory: [Int] = (0...10).map { _ in Int.random(in: 0..<10) }
}

public extension Array where Element == WidgetStanding {
    static var mock: [WidgetStanding] {
        [
            .init(rank: 1, points: 150, highlight: true),
            .init(rank: 2, points: 100, highlight: false),
            .init(rank: 3, points: 50, highlight: false)
        ]
    }
}
