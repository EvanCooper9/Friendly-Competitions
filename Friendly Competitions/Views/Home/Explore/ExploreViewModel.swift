import Combine
import CombineExt

final class ExploreViewModel: ObservableObject {
    
    @Published var loading = false
    @Published var searchText = ""
    @Published var searchResults = [Competition]()
    @Published var appOwnedCompetitions = [Competition]()

    init(competitionsManager: CompetitionsManaging) {
        competitionsManager.appOwnedCompetitions.assign(to: &$appOwnedCompetitions)
        
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
