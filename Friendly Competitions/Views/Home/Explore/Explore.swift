import SwiftUI

struct Explore: View {

    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager

    @State private var searchResults = [Competition]()
    @State private var searchText = ""

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if searchText.isEmpty {
                let carouselPadding = 20.0
                ExploreCarousel(title: "From us") {
                    ForEach($competitionsManager.appOwnedCompetitions) { $competition in
                        NavigationLink {
                            CompetitionView(competition: $competition)
                        } label: {
                            ExploreCompetition(competition: competition)
                                .frame(width: UIScreen.width - (carouselPadding * 2))
                        }
                        .buttonStyle(.flatLink)
                    }
                }
                .padding(.bottom, carouselPadding)

                VStack(alignment: .leading) {
                    Text("Top from the community")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach($competitionsManager.topCommunityCompetitions) { $competition in
                            NavigationLink {
                                CompetitionView(competition: $competition)
                            } label: {
                                ExploreCompetition(competition: competition)
                            }
                            .buttonStyle(.flatLink)
                            if competition.id != competitionsManager.topCommunityCompetitions.last?.id {
                                Divider().padding(.leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(colorScheme == .light ? .white : Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            } else {
                VStack {
                    ForEach($searchResults.filter(\.wrappedValue.appOwned)) { $competition in
                        NavigationLink {
                            CompetitionView(competition: $competition)
                        } label: {
                            ExploreCompetition(competition: competition)
                        }
                        .buttonStyle(.flatLink)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        let communitySearchResults = $searchResults.filter { !$0.wrappedValue.appOwned }
                        ForEach(communitySearchResults) { $competition in
                            NavigationLink {
                                CompetitionView(competition: $competition)
                            } label: {
                                ExploreCompetition(competition: competition)
                            }
                            .buttonStyle(.flatLink)
                            if competition.id != communitySearchResults.last?.id {
                                Divider().padding(.leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(colorScheme == .light ? .white : Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(colorScheme == .light ?
            Color(uiColor: .secondarySystemBackground).ignoresSafeArea() :
            nil
        )
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: searchText) { _ in
            Task {
                let competitions = try await competitionsManager.search(searchText)
                DispatchQueue.main.async {
                    self.searchResults = competitions
                }
            }
        }
        .navigationTitle("Explore")
        .embeddedInNavigationView()
        .tabItem {
            Label("Explore", systemImage: "sparkle.magnifyingglass")
        }
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
            .mock
        ]
        return competitionsManager
    }()

    static var previews: some View {
        Explore()
            .environmentObject(competitionsManager)
    }
}
