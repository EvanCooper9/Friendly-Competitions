import SwiftUI

struct MedalsView: View {
    let statistics: User.Medals

    var body: some View {
        MedalView(title: "🥇 Gold medals", value: statistics.golds)
        MedalView(title: "🥈 Silver medals", value: statistics.silvers)
        MedalView(title: "🥉 Bronze medals", value: statistics.bronzes)
    }   
}

struct MedalView: View {
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

#if DEBUG
struct MedalsView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            MedalsView(statistics: .mock)
        }
    }
}
#endif
