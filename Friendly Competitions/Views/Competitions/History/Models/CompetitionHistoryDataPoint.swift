import SwiftUI

enum CompetitionHistoryDataPoint: Identifiable {
    case rank(Int)
    case standings([Competition.Standing])
    case points(Int)
    
    var id: String { title }
    
    var title: String {
        switch self {
        case .rank:
            return "Rank"
        case .standings:
            return "Standings"
        case .points:
            return "Points"
        }
    }
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .rank(let rank):
            Text(rank.ordinalString!)
                .font(.largeTitle)
        case .standings(let standings):
            VStack {
                ForEach(standings) { standing in
                    HStack {
                        Text(standing.rank.ordinalString!)
                            .lineLimit(1)
                        Spacer()
                        Text(standing.points)
                            .lineLimit(1)
                    }
                }
            }
        case .points(let points):
            Text(points)
                .font(.largeTitle)
        }
    }
}
