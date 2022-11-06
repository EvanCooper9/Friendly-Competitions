import Charts
import SwiftUI
import SwiftUIX

struct CompetitionHistorySection: View {
    
    struct HistoryItem: Identifiable {
        var id: Date { date }
        
        let date: Date
        let rank: Int
        let points: Int
        
        func data(for metric: Metric) -> Int {
            switch metric {
            case .rank:
                return rank
            case .points:
                return points
            }
        }
    }
    
    let history: [HistoryItem]
    
    enum Metric: CaseIterable, CustomStringConvertible {
        case rank
        case points
        
        var description: String {
            switch self {
            case .rank:
                return "Rank"
            case .points:
                return "Points"
            }
        }
    }
    
    @State private var metric: Metric = .rank
    
    var body: some View {
        Section {
            if #available(iOS 16, *) {
                VStack(spacing: 20) {
                    Picker("Metric", selection: $metric.animation()) {
                        ForEach(Metric.allCases, id: \.description) { metric in
                            Text(metric.description).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Chart(history) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value(metric.description, item.data(for: metric))
                        )
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value(metric.description, item.data(for: metric))
                        )
                    }
                    .aspectRatio(1, contentMode: .fill)
                    
//                    Chart {
//                        ForEach(Array(history.enumerated()), id: \.offset) { offet, item in
//
//                            BarMark(
//                                x: .value("Date", item.date.formatted(date: .numeric, time: .omitted)),
//                                y: .value(metric.description, item.data(for: metric))
//                            )
//                        }
//                    }
                }
                .padding()
            } else {
                Text("Must be on iOS 16")
            }
        }
    }
}

struct CompetitionHistorySection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            CompetitionHistorySection(history: [
//                .init(date: .now.addingTimeInterval(-10.days), rank: 1, points: 100),
//                .init(date: .now.addingTimeInterval(-9.days), rank: 3, points: 50),
//                .init(date: .now.addingTimeInterval(-8.days), rank: 2, points: 75),
//                .init(date: .now.addingTimeInterval(-7.days), rank: 1, points: 100),
//                .init(date: .now.addingTimeInterval(-6.days), rank: 3, points: 50),
//                .init(date: .now.addingTimeInterval(-5.days), rank: 1, points: 100),
                .init(date: .now.addingTimeInterval(-4.days), rank: 1, points: 50),
                .init(date: .now.addingTimeInterval(-3.days), rank: 5, points: 75),
                .init(date: .now.addingTimeInterval(-2.days), rank: 3, points: 20),
                .init(date: .now.addingTimeInterval(-1.days), rank: 4, points: 90),
                .init(date: .now, rank: 2, points: 75)
            ])
        }
        .navigationTitle("Competition history")
        .embeddedInNavigationView()
    }
}
