import Combine
import CombineExt
import Factory
import Foundation

final class RootViewModel: ObservableObject {
    
    // MARK: - Public Properties
    
    @Published private(set)var tab = RootTab.home
    
    // MARK: - Private Properties
    
    @Injected(Container.appState) private var appState
    
    // MARK: - Lifecycle
    
    init() {
        appState.deepLink
            .unwrap()
            .mapToValue(.home)
            .assign(to: &$tab)
    }
}
