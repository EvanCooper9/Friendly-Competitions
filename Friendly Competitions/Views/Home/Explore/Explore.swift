import SwiftUI

struct Explore: View {

    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager

    @State private var searchResults = [Competition]()
    @State private var searchText = ""

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if searchText.isEmpty {
                ExploreSection(title: "From us") {
                    ExploreCarousel {
                        ForEach($competitionsManager.appOwnedCompetitions) { $competition in
                            competitionNavigation($competition) {
                                FeaturedCompetition(competition: competition)
                                    .frame(width: UIScreen.width - 30)
                            }
                        }
                    }
                }
                .padding(.bottom)

                ExploreSection(title: "Top from the community") {
                    communityCompetitions($competitionsManager.topCommunityCompetitions)
                        .padding(.horizontal)
                }
            } else {
                ExploreSection(title: "Search results") {
                    VStack {
                        ForEach($searchResults.filter(\.wrappedValue.appOwned)) { $competition in
                            competitionNavigation($competition) {
                                FeaturedCompetition(competition: competition)
                            }
                        }
                        communityCompetitions($searchResults)
                    }
                    .padding(.horizontal)
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
            }
            return
        }
        let competitions = try await competitionsManager
            .search(searchText)
            .sorted { lhs, rhs in
                lhs.appOwned && !rhs.appOwned
            }
        DispatchQueue.main.async {
            self.searchResults = competitions
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

    private func communityCompetitions(_ competitions: Binding<[Competition]>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            let competitions = competitions.filter { !$0.wrappedValue.appOwned }
            ForEach(competitions) { $competition in
                NavigationLink {
                    CompetitionView(competition: $competition)
                } label: {
                    ExploreCompetitionDetails(competition: competition)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.flatLink)
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

struct ExploreCompetitions_Previews: PreviewProvider {

    static let competitionsManager: AnyCompetitionsManager = {
        let competitionsManager = MockCompetitionManager()
        competitionsManager.appOwnedCompetitions = [
            .mockPublic,
            .mockPublic
        ]
        competitionsManager.topCommunityCompetitions = [
            .mock,
            .mock
        ]
        competitionsManager.searchResults = [
            .mockPublic,
            .mock,
            .mockPublic,
            .mock
        ]
        return competitionsManager
    }()

    static var previews: some View {
        Explore()
            .environmentObject(competitionsManager)
            .preferredColorScheme(.dark)
    }
}
