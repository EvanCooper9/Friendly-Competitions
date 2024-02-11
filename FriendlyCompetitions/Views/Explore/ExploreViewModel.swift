import Combine
import CombineExt
import CombineSchedulers
import Factory
import Foundation

final class ExploreViewModel: ObservableObject {

    @Published var navigationDestinations = [NavigationDestination]()

    @Published var loading = false
    @Published var searchText = ""
    @Published var searchResults = [Competition]()
    @Published var appOwnedCompetitions = [Competition]()

    @Published private(set) var showAds = false

    // MARK: - Private Properties

    @Injected(\.competitionsManager) private var competitionsManager: CompetitionsManaging
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging
    @Injected(\.scheduler) private var scheduler: AnySchedulerOf<RunLoop>
    @Injected(\.searchManager) private var searchManager: SearchManaging

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
            .receive(on: scheduler)
            .assign(to: &$searchResults)

        showAds = featureFlagManager.value(forBool: .adsEnabled)
    }
}
