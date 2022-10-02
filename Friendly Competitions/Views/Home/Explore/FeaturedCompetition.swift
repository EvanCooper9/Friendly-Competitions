import SwiftUI

struct FeaturedCompetition: View {

    let competition: Competition

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        color
            .aspectRatio(3/2, contentMode: .fit)
            .overlay {
                ZStack {
                    if let banner = competition.banner {
                        FirestoreImage(path: banner)
                    }

                    // has navigation link already
                    CompetitionDetails(competition: competition, showParticipantCount: true, isFeatured: true)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(.ultraThinMaterial)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .cornerRadius(10)
    }

    private var color: some View {
        colorScheme == .light ? Color(uiColor: .systemGray4) : Color.secondarySystemBackground
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
            .removingMargin()
        }
        .navigationTitle("Previews")
        .embeddedInNavigationView()
        .setupMocks(setupMocks)
//        .preferredColorScheme(.dark)
    }
}
