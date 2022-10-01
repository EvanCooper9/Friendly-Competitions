import SwiftUI

struct FeaturedCompetition: View {

    let competition: Competition

    @Environment(\.colorScheme) private var colorScheme

    private var start: String { competition.start.formatted(date: .abbreviated, time: .omitted) }
    private var end: String { competition.end.formatted(date: .abbreviated, time: .omitted) }

    var body: some View {
        color
            .aspectRatio(3/2, contentMode: .fit)
            .overlay {
                if let banner = competition.banner {
                    FirestoreImage(path: banner)
                } else {
                    Asset.Colors.listSectionBackground.swiftUIColor
                }
            }
            .clipped()
                .overlay {
                    // has navigation link already
                    CompetitionDetails(competition: competition, showParticipantCount: true, isFeatured: true)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(.ultraThinMaterial)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            .cornerRadius(10)
    }

    private var color: some View {
        colorScheme == .light ? Color(uiColor: .systemGray4) : Color(uiColor: .secondarySystemBackground)
    }
}

struct FeaturedCompetitionView_Previews: PreviewProvider {

    private static let competition = Competition.mockPublic

    private static func setupMocks() {
        competitionsManager.competitions = .just([competition])
        competitionsManager.standings = .just([:])
        competitionsManager.participants = .just([:])
        competitionsManager.pendingParticipants = .just([:])
        storageManager.dataForReturnValue = .init()
    }

    static var previews: some View {
        List {
            Section {
                FeaturedCompetition(competition: competition)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 10, trailing: 0))
            .listRowSeparator(.hidden)
        }
        .navigationTitle("Previews")
        .embeddedInNavigationView()
        .setupMocks(setupMocks)
    }
}
