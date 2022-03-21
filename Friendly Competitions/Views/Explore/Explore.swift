import SwiftUI

struct Explore: View {

    private enum Constants {
        static let horizontalPadding = 20.0
    }

    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager

    @State private var searchResults = [Competition]()
    @State private var searchText = ""
    @State private var loading = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if searchText.isEmpty {
                ExploreSection(title: "From us") {
                    ExploreCarousel(padding: Constants.horizontalPadding) {
                        ForEach($competitionsManager.appOwnedCompetitions) { $competition in
                            competitionNavigation($competition) {
                                FeaturedCompetition(competition: $competition)
                                    .frame(width: UIScreen.width - (Constants.horizontalPadding * 2))
                            }
                        }
                    }
                }
                .padding(.bottom)

                ExploreSection(title: "Top from the community") {
                    communityCompetitions($competitionsManager.topCommunityCompetitions)
                        .padding(.horizontal, Constants.horizontalPadding)
                }
            } else {
                ExploreSection(title: "Search results") {
                    if loading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if searchResults.isEmpty {
                        Text("Nothing here")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        VStack {
                            ForEach($searchResults.filter(\.wrappedValue.appOwned)) { $competition in
                                competitionNavigation($competition) {
                                    FeaturedCompetition(competition: $competition)
                                }
                            }
                            communityCompetitions($searchResults)
                        }
                        .padding(.horizontal, Constants.horizontalPadding)
                    }
                }
            }
        }
        .background(Asset.Colors.listBackground.swiftUIColor)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: searchText) { _ in
            Task { try await search() }
        }
        .task { try? await search() }
        .navigationTitle("Explore")
        .embeddedInNavigationView()
        .tabItem { Label("Explore", systemImage: "sparkle.magnifyingglass") }
    }

    private func search() async throws {
        guard !searchText.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
                self.loading = false
            }
            return
        }
        DispatchQueue.main.async {
            self.loading = true
        }
        let competitions = try await competitionsManager
            .search(searchText)
            .sorted { lhs, rhs in
                lhs.appOwned && !rhs.appOwned
            }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.searchResults = competitions
            self.loading = false
        }
    }

    private func competitionNavigation<Label: View>(_ competition: Binding<Competition>, label: () -> Label) -> some View {
        NavigationLink {
            CompetitionView(competition: competition)
        } label: {
            label()
        }
        .buttonStyle(.flatLink)
    }

    @ViewBuilder
    private func communityCompetitions(_ competitions: Binding<[Competition]>) -> some View {
        let competitions = competitions.filter { !$0.wrappedValue.appOwned }
        if !competitions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(competitions) { $competition in
                    CompetitionDetails(competition: $competition)
                    if competition.id != competitions.last?.id {
                        Divider().padding(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Asset.Colors.listSectionBackground.swiftUIColor)
            .cornerRadius(10)
        }
    }
}

struct ExploreCompetitions_Previews: PreviewProvider {
    static var previews: some View {
        Explore()
            .withEnvironmentObjects()
//            .preferredColorScheme(.dark)
    }
}
