import SwiftUI

struct ExploreCompetitions: View {

    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager

    @State private var searchText = ""

    var body: some View {
        ScrollView(.vertical) {
            VStack {

                ExploreCarouselSection(title: "By Friendly Competitions") {
                    ForEach($competitionsManager.publicCompetitions) { $competition in
                        NavigationLink {
                            CompetitionView(competition: $competition)
                        } label: {
                            FeaturedCompetitionView(competition: competition)
                                .frame(width: 350)
                        }
                    }
                }

                Divider()
                    .padding(.leading)

                ExploreCarouselSection(title: "Near you") {
                    ForEach(competitionsManager.publicCompetitions) { competition in
                        FeaturedCompetitionView(competition: competition)
                            .frame(width: 350)
                    }
                }
            }
        }
        .navigationTitle("Explore")
        .embeddedInNavigationView()
    }
}

struct ExploreCompetitions_Previews: PreviewProvider {

    static let competitionsManager: AnyCompetitionsManager = {
        let competitionsManager = AnyCompetitionsManager()
        competitionsManager.publicCompetitions = [
            .mock,
            .mockOld
        ]
        return competitionsManager
    }()

    static var previews: some View {
        Group {
            ExploreCompetitions()
            ExploreCompetitions()
                .preferredColorScheme(.dark)

        }
        .environmentObject(competitionsManager)
    }
}
