import Resolver
import SwiftUI

struct CompetitionDetails: View {

    @Binding var competition: Competition
    let showParticipantCount: Bool
    let isFeatured: Bool

    @Environment(\.colorScheme) private var colorScheme

    @InjectedObject private var competitionsManager: AnyCompetitionsManager
    @InjectedObject private var userManager: AnyUserManager

    var body: some View {
        print(Self._printChanges())
        print(competition)
        return NavigationLink(destination: CompetitionView(competition: $competition)) {
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

struct CompetitionDetails_Previews: PreviewProvider {
    static var previews: some View {
        List {
            CompetitionDetails(competition: .constant(.mock), showParticipantCount: true, isFeatured: false)
            CompetitionDetails(competition: .constant(.mock), showParticipantCount: true, isFeatured: false)
        }
    }
}
