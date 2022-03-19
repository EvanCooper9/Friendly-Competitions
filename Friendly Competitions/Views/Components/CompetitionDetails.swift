import SwiftUI

struct CompetitionDetails: View {

    @Binding var competition: Competition

    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager
    @EnvironmentObject private var userManager: AnyUserManager

    var body: some View {
        NavigationLink(destination: CompetitionView(competition: $competition)) {
            HStack(alignment: .center) {
                if competition.owner == Bundle.main.id {
                    AppIcon(size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
                }
                VStack(alignment: .leading) {
                    Text(competition.name)
                        .foregroundColor(colorScheme == .light ? .black : .white)
                    Text("\(competition.ended ? "ended" : "ends") \(RelativeDateTimeFormatter().localizedString(for: competition.end, relativeTo: .now))")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Spacer()

                if competition.pendingParticipants.contains(userManager.user.id) {
                    Text("Invited")
                        .foregroundColor(.gray)
                } else if competition.ended,
                      let standings = competitionsManager.standings[competition.id],
                      let rank = standings.first(where: { $0.userId == userManager.user.id })?.rank,
                      let rankEmoji = rank.rankEmoji {
                    Text(rankEmoji)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private extension Int {
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
