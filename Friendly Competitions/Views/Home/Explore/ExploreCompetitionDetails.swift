import SwiftUI

struct ExploreCompetitionDetails: View {

    let competition: Competition

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                if competition.owner == Bundle.main.id {
                    AppIcon(size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
                }
                Text(competition.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title3)
                Spacer()
                Label("\(competition.participants.count)", systemImage: "person.3.sequence.fill")
                    .font(.footnote)
            }
            let start = competition.start.formatted(date: .abbreviated, time: .omitted)
            let end = competition.end.formatted(date: .abbreviated, time: .omitted)
            let text = "\(start) - \(end)"
            Label(text, systemImage: "calendar")
                .font(.footnote)
        }
    }
}
