import SwiftUI

struct StatisticsView: View {
    let statistics: User.Statistics

    var body: some View {
        StatisticView(title: "🥇 Gold medals", value: statistics.golds)
        StatisticView(title: "🥈 Silver medals", value: statistics.silvers)
        StatisticView(title: "🥉 Bronze medals", value: statistics.bronzes)
    }
}

struct StatisticView: View {
    let title: String
    let value: Int

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .foregroundColor(.gray)
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section {
                StatisticsView(statistics: .mock)
            }
        }
    }
}
