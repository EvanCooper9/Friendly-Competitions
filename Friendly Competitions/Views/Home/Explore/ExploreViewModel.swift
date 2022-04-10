import Combine
import CombineExt
import Resolver

final class ExploreViewModel: ObservableObject {
    
    @Published var loading = false
    @Published var searchText = ""
    @Published var searchResults = [Competition]()
    
    @Published var appOwnedCompetitions = [Competition]()
    @Published var topCommunityCompetitions = [Competition]()
    
    @Injected private var competitionsManager: AnyCompetitionsManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        
        competitionsManager.$appOwnedCompetitions
            .assign(to: \.appOwnedCompetitions, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        competitionsManager.$topCommunityCompetitions
            .assign(to: \.topCommunityCompetitions, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        $searchText
            .sinkAsync { [weak self] searchText in
                guard let self = self else { return }
                guard !searchText.isEmpty else {
                    self.searchResults = []
                    self.loading = false
                    return
                }
                
                self.loading = true
                let competitions = try await self.competitionsManager
                    .search(searchText)
                    .sorted { lhs, rhs in
                        lhs.appOwned && !rhs.appOwned
                    }
                self.searchResults = competitions
                self.loading = false
            }
            .store(in: &cancellables)
    }
}
