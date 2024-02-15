import ECKit
import Factory
import SwiftUI

struct ExploreView: View {

    private enum Constants {
        static let horizontalPadding = 20.0
    }

    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        NavigationStack(path: $viewModel.navigationDestinations) {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.searchText.isEmpty {
                        ForEach(viewModel.appOwnedCompetitions) { competition in
                            ZStack {
                                NavigationLink(value: NavigationDestination.competition(competition, nil)) { EmptyView() }
                                    .opacity(0)
                                FeaturedCompetition(competition: competition)
                            }
                            .padding(.horizontal)
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
                                ZStack {
                                    NavigationLink(value: NavigationDestination.competition(competition, nil)) { EmptyView() }
                                        .opacity(0)
                                    FeaturedCompetition(competition: competition)
                                }
                                .padding(.horizontal)
                            }
                            ForEach(viewModel.searchResults.filter(\.appOwned.not)) { competition in
                                ZStack {
                                    NavigationLink(value: NavigationDestination.competition(competition, nil)) { EmptyView() }
                                        .opacity(0)
                                    CompetitionDetails(competition: competition, showParticipantCount: true, isFeatured: false)
                                        .padding(.vertical, .small)
                                        .padding(.horizontal)
                                        .background(.systemFill)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    if viewModel.showAds {
                        GoogleAd(unit: .native)
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                }
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(L10n.Explore.title)
            .registerScreenView(name: "Explore")
            .navigationDestination(for: NavigationDestination.self) { $0.view }
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
