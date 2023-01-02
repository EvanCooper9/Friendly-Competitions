import Factory
import SwiftUI

struct ExploreView: View {

    private enum Constants {
        static let horizontalPadding = 20.0
    }

    @StateObject private var viewModel = ExploreViewModel()
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationDestinations) {
            List {
                if viewModel.searchText.isEmpty {
                    Section {
                        ForEach(viewModel.appOwnedCompetitions) { competition in
                            FeaturedCompetition(competition: competition)
                        }
                    }
                    .removingMargin()
                } else {
                    Section {
                        if viewModel.searchResults.isEmpty {
                            Text("Nothing here")
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(viewModel.searchResults.filter(\.appOwned)) { competition in
                                NavigationLink(value: NavigationDestination.competition(competition)) {
                                    FeaturedCompetition(competition: competition)
                                }
                            }
                            ForEach(viewModel.searchResults.filter(\.appOwned.not)) { competition in
                                NavigationLink(value: NavigationDestination.competition(competition)) {
                                    CompetitionDetails(competition: competition, showParticipantCount: true, isFeatured: false)
                                        .padding()
                                        .background(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .removingMargin()
                }
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Explore")
            .registerScreenView(name: "Explore")
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .competition(let competition):
                    CompetitionView(competition: competition)
                case .competitionHistory(let competition):
                    CompetitionHistoryView(competition: competition)
                case .user(let user):
                    UserView(user: user)
                }
            }
        }
    }
}

#if DEBUG
struct ExploreCompetitions_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .embeddedInNavigationView()
            .setupMocks()
    }
}
#endif
