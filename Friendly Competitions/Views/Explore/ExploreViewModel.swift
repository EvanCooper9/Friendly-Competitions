import Combine
import CombineExt
import Factory

final class ExploreViewModel: ObservableObject {
    
    @Published var navigationDestinations = [NavigationDestination]()
    
    @Published var loading = false
    @Published var searchText = ""
    @Published var searchResults = [Competition]()
    @Published var appOwnedCompetitions = [Competition]()
    
    // MARK: - Private Properties
    
    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.searchManager) private var searchManager
    
    // MARK: - Lifecycle

    init() {
        competitionsManager.appOwnedCompetitions.assign(to: &$appOwnedCompetitions)
        
        $searchText
            .flatMapLatest(withUnretained: self) { strongSelf, searchText -> AnyPublisher<[Competition], Never> in
                guard !searchText.isEmpty else { return .just([]) }
                return strongSelf.searchManager
                    .searchForCompetitions(byName: searchText)
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
            }
            .assign(to: &$searchResults)
    }
}
