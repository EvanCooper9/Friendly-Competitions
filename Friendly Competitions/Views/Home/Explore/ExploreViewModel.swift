import Combine
import CombineExt
import Resolver

final class ExploreViewModel: ObservableObject {
    
    @Published var loading = false
    @Published var searchText = ""
    @Published var searchResults = [Competition]()
    @Published var appOwnedCompetitions = [Competition]()
    @Published var topCommunityCompetitions = [Competition]()
        
    @Injected private var competitionsManager: CompetitionsManaging
    
    init() {
        competitionsManager.appOwnedCompetitions.assign(to: &$appOwnedCompetitions)
        competitionsManager.topCommunityCompetitions.assign(to: &$topCommunityCompetitions)
        
        $searchText
            .handleEvents(receiveOutput: { [weak self] _ in self?.loading = true })
            .setFailureType(to: Error.self)
            .flatMapLatest(competitionsManager.search)
            .ignoreFailure()
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] _ in self?.loading = false })
            .assign(to: &$searchResults)
    }
}
