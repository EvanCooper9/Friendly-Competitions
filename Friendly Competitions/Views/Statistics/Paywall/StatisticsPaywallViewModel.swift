import Combine
import CombineExt
import ECKit
import Factory

final class StatisticsPaywallViewModel: ObservableObject {

    // MARK: - Public Properties

    // MARK: - Private Properties
    
    @Injected(Container.storeKitManager) private var storeKitManager

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {}

    // MARK: - Public Methods
    
    func purchaseTapped() {
        
    }
}
