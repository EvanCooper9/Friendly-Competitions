import ECKit
import Factory
import SwiftUI

struct ExploreView: View {

    private enum Constants {
        static let horizontalPadding = 20.0
    }

    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        ScrollView {
            if viewModel.searchText.isEmpty {
                ForEach(viewModel.appOwnedCompetitions) { competition in
                    featured(competition)
                }
            } else {
                if viewModel.searchResults.isEmpty {
                    Text(L10n.Explore.Search.nothingHere)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(viewModel.searchResults.filter(\.appOwned)) { competition in
                        featured(competition)
                    }
                    ForEach(viewModel.searchResults.filter(\.appOwned.not)) { competition in
                        NavigationLink(value: NavigationDestination.competition(competition, nil)) {
                            CompetitionDetails(competition: competition, showParticipantCount: true, isFeatured: false)
                                .padding(.vertical, .small)
                                .padding(.horizontal)
                                .background(.systemFill)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let unit = viewModel.googleAdUnit {
                Section {
                    GoogleAd(unit: unit)
                }
                .listRowInsets(.zero)
            }
        }
        .background(Color.listBackground)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle(L10n.Explore.title)
        .registerScreenView(name: "Explore")
        .embeddedInNavigationStack(path: $viewModel.navigationDestinations)
        .navigationDestination(for: NavigationDestination.self) { $0.view }
    }

    private func featured(_ competition: Competition) -> some View {
        NavigationLink(value: NavigationDestination.competition(competition, nil)) {
            FeaturedCompetition(competition: competition)
                .padding(.horizontal)
        }
        .buttonStyle(.plain)
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
