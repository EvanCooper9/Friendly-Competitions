import Combine
import CombineExt
import Resolver

final class ExploreViewModel: ObservableObject {
    
    @Published var loading = false
    @Published var searchText = ""
    @Published var searchResults = [Competition]()
    @Published var appOwnedCompetitions = [Competition]()

    init(competitionsManager: CompetitionsManaging) {

        competitionsManager.appOwnedCompetitions.assign(to: &$appOwnedCompetitions)
        
        $searchText
            .flatMapLatest { searchText -> AnyPublisher<[Competition], Never> in
                guard !searchText.isEmpty else { return .just([]) }
                return competitionsManager.search(searchText)
                    .receive(on: RunLoop.main)
                    .isLoading { [weak self] in self?.loading = $0 }
                    .ignoreFailure()
            }
            .assign(to: &$searchResults)
    }
}
