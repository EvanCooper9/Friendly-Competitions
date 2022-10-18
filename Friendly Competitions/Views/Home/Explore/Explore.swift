import Factory
import SwiftUI

struct Explore: View {

    private enum Constants {
        static let horizontalPadding = 20.0
    }

    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel = ExploreViewModel()
    
    var body: some View {
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
                            FeaturedCompetition(competition: competition)
                        }
                        ForEach(viewModel.searchResults.filter(\.appOwned.not)) { competition in
                            CompetitionDetails(competition: competition, showParticipantCount: true, isFeatured: false)
                                .padding()
                                .background(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .removingMargin()
            }
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Explore")
        .registerScreenView(name: "Explore")
    }
}

#if DEBUG
struct ExploreCompetitions_Previews: PreviewProvider {
    static var previews: some View {
        Explore()
            .embeddedInNavigationView()
            .setupMocks()
    }
}
#endif
