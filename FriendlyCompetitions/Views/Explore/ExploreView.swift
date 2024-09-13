import ECKit
import Factory
import SwiftUI

struct ExploreView: View {

    private enum Constants {
        static let horizontalPadding = 20.0
    }

    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        List {
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
                        Section {
                            CompetitionDetails(competition: competition, showParticipantCount: true, isFeatured: false)
                                .navigationLinked(to: NavigationDestination.competition(competition, nil))
                        }
                    }
                }
            }

            if let unit = viewModel.googleAdUnit {
                ad(unit: unit)
            }
        }
        .background(Color.listBackground)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle(L10n.Explore.title)
        .registerScreenView(name: "Explore")
        .navigationDestination(for: NavigationDestination.self) { $0.view }
        .embeddedInNavigationStack(path: $viewModel.navigationDestinations)
    }

    private func featured(_ competition: Competition) -> some View {
        Section {
            FeaturedCompetition(competition: competition)
                .navigationLinked(to: NavigationDestination.competition(competition, nil))
        }
        .listRowInsets(.zero)
    }

    private func ad(unit: GoogleAdUnit) -> some View {
        Section {
            GoogleAd(unit: unit)
        }
        .listRowInsets(.zero)
    }
}

extension View {
    func navigationLinked<Destination: Hashable>(to destination: Destination) -> some View {
        self.overlay {
            NavigationLink(value: destination) {
                Color.clear
            }
            .buttonStyle(.plain)
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
