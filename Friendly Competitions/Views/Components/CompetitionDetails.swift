import SwiftUI

struct CompetitionDetails: View {

    @Binding var competition: Competition
    let showParticipantCount: Bool
    let isFeatured: Bool

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
                    Text("\(competition.ended ? "ended" : "ends") \(RelativeDateTimeFormatter().localizedString(for: competition.trueEnd, relativeTo: .now))")
                        .font(.footnote)
                        .foregroundColor(subtitleColor)
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
                } else if showParticipantCount {
                    Label("\(competition.participants.count)", systemImage: "person.3.fill")
                        .foregroundColor(colorScheme.textColor)
                        .font(.footnote)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.flatLink)
    }
    
    private var subtitleColor: Color {
        guard isFeatured else { return .gray }
        return colorScheme == .light ? .gray : .white
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
