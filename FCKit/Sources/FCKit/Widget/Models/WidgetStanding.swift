import Foundation

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
}

public extension Array where Element == WidgetStanding {
    static var mock: [WidgetStanding] {
        [
            .init(rank: 1, points: 150_000, highlight: true),
            .init(rank: 2, points: 100_000, highlight: false),
            .init(rank: 3, points: 50_000, highlight: false)
        ]
    }

    var highlighted: WidgetStanding? {
        first(where: { $0.highlight })
    }
}
