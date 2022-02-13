import SwiftUI
import Resolver

struct CompetitionListItem: View {

    let competition: Competition

    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager
    @EnvironmentObject private var userManager: AnyUserManager

    var body: some View {
        NavigationLink(destination: CompetitionView(competition: competition)) {
            HStack {
                Text(competition.name)
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
