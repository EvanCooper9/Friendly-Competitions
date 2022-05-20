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
    
    init() {
        competitionsManager.$appOwnedCompetitions.assign(to: &$appOwnedCompetitions)
        competitionsManager.$topCommunityCompetitions.assign(to: &$topCommunityCompetitions)
        
        $searchText
            .handleEvents(receiveOutput: { [weak self] _ in self?.loading = true })
            .flatMapLatest { [weak self] searchText -> AnyPublisher<[Competition], Never> in
                guard let self = self else { return .just([]) }
                let subject = PassthroughSubject<[Competition], Never>()
                Task {
                    let competitions = try await self.competitionsManager
                        .search(searchText)
                        .sorted { lhs, rhs in
                            lhs.appOwned && !rhs.appOwned
                        }
                    subject.send(competitions)
                }
                return subject.eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] _ in self?.loading = false })
            .assign(to: &$searchResults)
    }
}
