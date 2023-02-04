import ECKit
import SwiftUI

extension CompetitionResultsDataPoint {
    
    @ViewBuilder
    var view: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.callout)
                .foregroundColor(.secondaryLabel)
            Card {
                content
                    .maxWidth(.infinity)
                    .maxHeight(.infinity)
            }
            .aspectRatio(1, contentMode: .fill)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch self {
        case let .rank(current, previous):
            ZStack {
                if let rankEmoji = current.rankEmoji {
                    Text(rankEmoji)
                        .font(.title)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                Text(current.ordinalString!)
                    .font(.largeTitle)
                trendIcon(current: current, previous: previous, goal: .low)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        case .standings(let standings):
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(standings, id: \.rank) { standing in
                        HStack(spacing: 0) {
                            Text(standing.rank.ordinalString!)
                                .lineLimit(1)
                            Spacer()
                            Text(standing.points)
                                .lineLimit(1)
                        }
                        .font(standing.isHighlighted ? .title2 : .title3)
                        .padding(.vertical, .small)
                        .padding(.horizontal)
                        .background(standing.isHighlighted ? .accentColor : .systemFill)
                        .foregroundColor(standing.isHighlighted ? .white : .label)
                        .bold(standing.isHighlighted)
                        .cornerRadius(5)
                        .id(standing.rank)
                    }
                    .padding(20)
                }
                .onAppear {
                    guard let id = standings.first(where: \.isHighlighted)?.rank else { return }
                    proxy.scrollTo(id, anchor: .center)
                }
            }
            .padding(-20)
        case let .points(current, previous):
            ZStack {
                Text(current)
                    .font(.largeTitle)
                trendIcon(current: current, previous: previous, goal: .high)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        case .activitySummaryBestDay(let activitySummary):
            VStack {
                Text(L10n.Results.ActivitySummaries.BestDay.message)
                ActivityRingView(activitySummary: activitySummary?.hkActivitySummary)
                    .aspectRatio(1, contentMode: .fit)
            }
        case let .activitySummaryCloseCount(current, previous):
            ZStack {
                VStack {
                    Text(L10n.Results.ActivitySummaries.RingsClosed.message)
                    Text(current)
                        .font(.largeTitle)
                }
                trendIcon(current: current, previous: previous, goal: .high)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        case .workoutsBestDay(let workout):
            VStack(alignment: .leading) {
                Text(L10n.Results.Workouts.BestDay.message)
                if let workout {
                    VStack {
                        ForEach(Array(workout.points.keys)) { key in
                            HStack {
                                Text(key.description)
                                Spacer()
                                Text(workout.points[key]!)
                            }
                            .padding(.small)
                            .background(.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                        }
                        Spacer()
                    }
                } else {
                    Text(L10n.Results.Workouts.BestDay.nothingHere)
                        .foregroundColor(.secondaryLabel)
                }
            }
        }
    }
    
    private enum Goal {
        case low
        case high
    }
    
    @ViewBuilder
    private func trendIcon(current: Int, previous: Int?, goal: Goal) -> some View {
        if let previous {
            
            let trendImage: String = {
                if current > previous {
                    return goal == .low ? "chart.line.downtrend.xyaxis" : "chart.line.uptrend.xyaxis"
                } else if current < previous {
                    return goal == .low ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis"
                }
                return "chart.line.flattrend.xyaxis"
            }()
            
            let trendColor: Color = {
                if current > previous {
                    return goal == .low ? .red : .green
                } else if current < previous {
                    return goal == .low ? .green : .red
                }
                return .gray
            }()
            
            HStack {
                Image(systemName: trendImage)
                Text(abs(current - previous))
            }
            .foregroundColor(trendColor)
            .padding(.vertical, .small)
            .padding(.horizontal)
            .overlay(Capsule().stroke(trendColor))
        }
    }
}

extension Int {
    var rankEmoji: String? {
        switch self {
        case 1:
            return "🥇"
        case 2:
            return "🥈"
        case 3:
            return "🥉"
        default:
            return nil
        }
    }
}

#if DEBUG
struct CompetitionResultsDataPoint_Previews: PreviewProvider {
    
    private static let data: [CompetitionResultsDataPoint] = [
        .rank(current: 3, previous: 1),
//        .rank(current: 5, previous: nil),
        .points(current: 500, previous: 447),
        .standings(
            [
                .init(rank: 1, points: 600, isHighlighted: false),
                .init(rank: 2, points: 500, isHighlighted: true),
                .init(rank: 3, points: 400, isHighlighted: false),
                .init(rank: 4, points: 300, isHighlighted: false),
            ]
        ),
        .workoutsBestDay(.init(type: .running, date: .now, points: [.distance: 100, .steps: 500])),
        .activitySummaryBestDay(.mock),
        .activitySummaryCloseCount(current: 34, previous: 20)
    ]
    
    static var previews: some View {
        ScrollView {
            LazyVGrid(columns: [.flexible(), .flexible()]) {
                ForEach(data) { $0.view }
            }
            .padding()
        }
    }
}
#endif
