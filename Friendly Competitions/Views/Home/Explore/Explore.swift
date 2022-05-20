import SwiftUI

struct Explore: View {

    private enum Constants {
        static let horizontalPadding = 20.0
    }

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState

    @StateObject private var viewModel = ExploreViewModel()
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if viewModel.searchText.isEmpty {
                ExploreSection(title: "From us") {
                    ExploreCarousel(padding: Constants.horizontalPadding) {
                        ForEach(viewModel.appOwnedCompetitions) { competition in
                            FeaturedCompetition(competition: competition)
                                .frame(width: UIScreen.width - (Constants.horizontalPadding * 2))
                        }
                    }
                }
                .padding(.bottom)

                ExploreSection(title: "Top from the community") {
                    CommunityCompetitions(competitions: viewModel.topCommunityCompetitions)
                        .padding(.horizontal, Constants.horizontalPadding)
                }
            } else {
                ExploreSection(title: "Search results") {
                    if viewModel.searchResults.isEmpty {
                        Text("Nothing here")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        VStack {
                            ForEach(viewModel.searchResults.filter(\.appOwned)) { competition in
                                FeaturedCompetition(competition: competition)
                            }
                            CommunityCompetitions(competitions: viewModel.searchResults.filter(\.appOwned.not))
                        }
                        .padding(.horizontal, Constants.horizontalPadding)
                    }
                }
            }
        }
        .background(Asset.Colors.listBackground.swiftUIColor)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Explore")
        .registerScreenView(name: "Explore")
    }
}

private struct CommunityCompetitions: View {
    
    let competitions: [Competition]
    
    var body: some View {
        VStack {
            ForEach(competitions) { competition in
                CompetitionDetails(competition: competition, showParticipantCount: true, isFeatured: false)
                    .padding(.horizontal)
                if competition.id != competitions.last?.id {
                    Divider().padding(.leading)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Asset.Colors.listSectionBackground.swiftUIColor)
        .cornerRadius(10)
    }
}

struct ExploreCompetitions_Previews: PreviewProvider {
    
    private static func setupMocks() {
        competitionsManager.appOwnedCompetitions = [.mockPublic]
        competitionsManager.topCommunityCompetitions = [.mock, .mock, .mock]
    }
    
    static var previews: some View {
        Explore()
            .setupMocks(setupMocks)
//            .preferredColorScheme(.dark)
    }
}
