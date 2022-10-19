import Combine
import CombineExt
import Factory

final class ExploreViewModel: ObservableObject {
    
    @Published var loading = false
    @Published var searchText = ""
    @Published var searchResults = [Competition]()
    @Published var appOwnedCompetitions = [Competition]()
    
    // MARK: - Private Properties
    
    @Injected(Container.competitionsManager) private var competitionsManager
    
    // MARK: - Lifecycle

    init() {
        competitionsManager.appOwnedCompetitions
            .print("app owned competitions")
            .assign(to: &$appOwnedCompetitions)
        
        $searchText
            .flatMapLatest(withUnretained: self) { strongSelf, searchText -> AnyPublisher<[Competition], Never> in
                guard !searchText.isEmpty else { return .just([]) }
                return strongSelf.competitionsManager.search(searchText)
                    .isLoading { [weak self] in self?.loading = $0 }
                    .ignoreFailure()
            }
            .assign(to: &$searchResults)
    }
}
