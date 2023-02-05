import Combine
import CombineExt
import Factory
import Foundation

final class RootViewModel: ObservableObject {
    
    // MARK: - Public Properties
    
    @Published var tab = RootTab.home
    
    // MARK: - Private Properties
    
    @Injected(Container.appState) private var appState
    
    // MARK: - Lifecycle
    
    init() {
        appState.deepLink
            .unwrap()
            .removeDuplicates()
            .mapToValue(.home)
            .assign(to: &$tab)
    }
}
