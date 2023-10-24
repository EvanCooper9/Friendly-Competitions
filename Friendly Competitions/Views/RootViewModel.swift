import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class RootViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published var tab = RootTab.home

    // MARK: - Private Properties

    @Injected(\.appState) private var appState
    @Injected(\.scheduler) private var scheduler

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        appState.deepLink
            .unwrap()
            .removeDuplicates()
            .mapToValue(.home)
            .assign(to: &$tab)

        appState.rootTab
            .receive(on: scheduler)
            .sink(withUnretained: self) { $0.tab = $1 }
            .store(in: &cancellables)
    }
}
