import SwiftUI

struct Explore: View {

    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager

    @State private var searchResults = [Competition]()
    @State private var searchText = ""

    private var appOwnedCompetitions: [Competition] {
        competitionsManager.publicCompetitions.filter(\.appOwned)
    }

    private var communityCompetitions: [Competition] {
        competitionsManager.publicCompetitions.filter { !$0.appOwned }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if searchText.isEmpty {
                ExploreCarousel(title: "From us") {
                    ForEach(appOwnedCompetitions) { competition in
                        NavigationLink {
                            CompetitionView(competition: .constant(competition))
                        } label: {
                            FeaturedCompetition(competition: competition)
                                .frame(width: UIScreen.width - 40)
                        }
                        .buttonStyle(.flatLink)
                    }
                }
                .padding(.bottom, 20)

                VStack(alignment: .leading) {
                    Text("From the community")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(communityCompetitions) { competition in
                            NavigationLink {
                                CompetitionView(competition: .constant(competition))
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(competition.name)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(.title3)

                                    let start = competition.start.formatted(date: .abbreviated, time: .omitted)
                                    let end = competition.end.formatted(date: .abbreviated, time: .omitted)
                                    let text = "\(start) - \(end)"
                                    Label(text, systemImage: "calendar")
                                        .font(.footnote)
                                }
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.flatLink)
                            if competition.id != communityCompetitions.last?.id {
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
                ForEach(searchResults) { competition in
                    NavigationLink {
                        CompetitionView(competition: .constant(competition))
                    } label: {
                        FeaturedCompetition(competition: competition)
                            .frame(width: UIScreen.width - 40)
                    }
                    .buttonStyle(.flatLink)
                }
                .padding(.horizontal)
            }
        }
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
        let competitionsManager = AnyCompetitionsManager()
        competitionsManager.publicCompetitions = [
            .mockPublic,
            .mockPublic,
            .mock,
            .mock
        ]
        return competitionsManager
    }()

    static var previews: some View {
        Explore()
            .environmentObject(competitionsManager)
    }
}
