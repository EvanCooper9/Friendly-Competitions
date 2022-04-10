import SwiftUI

struct CompetitionDetails: View {

    let competition: Competition
    let showParticipantCount: Bool
    let isFeatured: Bool

    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var viewModel: CompetitionDetailsViewModel
    
    init(competition: Competition, showParticipantCount: Bool, isFeatured: Bool) {
        _viewModel = StateObject(wrappedValue: CompetitionDetailsViewModel(competition: competition))
        self.competition = competition
        self.showParticipantCount = showParticipantCount
        self.isFeatured = isFeatured
    }

    var body: some View {
        NavigationLink {
            CompetitionView(competition: competition)
        } label: {
            HStack(alignment: .center) {
                if competition.owner == Bundle.main.id {
                    AppIcon(size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
                }
                VStack(alignment: .leading) {
                    Text(competition.name)
                    
                    let referenceDate = competition.started ? competition.trueEnd : competition.start
                    let endString = competition.ended ? "ended" : "ends"
                    let startString = "starts"
                    Text("\(competition.started ? endString : startString) \(RelativeDateTimeFormatter().localizedString(for: referenceDate, relativeTo: .now))")
                        .font(.footnote)
                        .foregroundColor(subtitleColor)
                }

                Spacer()

                if viewModel.isInvitation {
                    Text("Invited")
                        .foregroundColor(.gray)
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

struct CompetitionDetails_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                CompetitionDetails(competition: .mockFuture, showParticipantCount: true, isFeatured: false)
                CompetitionDetails(competition: .mock, showParticipantCount: true, isFeatured: false)
                CompetitionDetails(competition: .mockOld, showParticipantCount: true, isFeatured: false)
            }
            .navigationTitle("Previews")
        }
        .withEnvironmentObjects()
    }
}
