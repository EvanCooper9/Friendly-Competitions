import Combine
import CombineExt
import ECKit

final class StatisticsViewModel: ObservableObject {

    // MARK: - Public Properties
    
    @Published private(set) var showPaywall = true

    // MARK: - Private Properties

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {}

    // MARK: - Public Methods
}
