import ECKit
import SwiftUI

struct CompetitionDetails: View {

    let competition: Competition
    let showParticipantCount: Bool
    let isFeatured: Bool

    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel: CompetitionDetailsViewModel

    init(competition: Competition, showParticipantCount: Bool, isFeatured: Bool) {
        _viewModel = .init(wrappedValue: .init(competition: competition))
        self.competition = competition
        self.showParticipantCount = showParticipantCount
        self.isFeatured = isFeatured
    }

    var body: some View {
        HStack(alignment: .center) {
            if competition.owner == Bundle.main.id {
                AppIcon(size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
            }
            VStack(alignment: .leading) {
                Text(competition.name)

                let referenceDate = competition.started ? competition.end : competition.start
                let endString = competition.ended ? L10n.Competition.Details.ended.localizedLowercase : L10n.Competition.Details.ends.localizedLowercase
                let startString = L10n.Competition.Details.starts.localizedLowercase
                Text("\(competition.started ? endString : startString) \(RelativeDateTimeFormatter().localizedString(for: referenceDate, relativeTo: .now))")
                    .font(.footnote)
                    .foregroundColor(subtitleColor)
            }

            Spacer()

            if viewModel.isInvitation {
                Text(L10n.InviteFriends.invited)
                    .foregroundColor(.gray)
            } else if showParticipantCount {
                Label("\(competition.participants.count)", systemImage: .person3Fill)
                    .foregroundColor(colorScheme.textColor)
                    .font(.footnote)
                    .monospaced()
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private var subtitleColor: Color {
        guard isFeatured else { return .gray }
        return colorScheme == .light ? .gray : .white
    }
}

#if DEBUG
struct CompetitionDetails_Previews: PreviewProvider {
    static var previews: some View {
        List {
            CompetitionDetails(competition: .mockPublic, showParticipantCount: false, isFeatured: true)
            CompetitionDetails(competition: .mockFuture, showParticipantCount: true, isFeatured: false)
            CompetitionDetails(competition: .mock, showParticipantCount: true, isFeatured: false)
            CompetitionDetails(competition: .mockOld, showParticipantCount: true, isFeatured: false)
        }
        .navigationTitle("Previews")
        .setupMocks()
    }
}
#endif
