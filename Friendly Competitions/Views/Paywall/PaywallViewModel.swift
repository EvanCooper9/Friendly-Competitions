import Combine
import CombineExt
import ECKit
import Factory

final class PaywallViewModel: ObservableObject {
    
    struct Offer: Identifiable {
        let product: FriendlyCompetitionsProduct
        let selected: Bool
        
        var id: FriendlyCompetitionsProduct.ID { product.id }
    }

    // MARK: - Public Properties
    
    @Published private(set) var offers = [Offer]()
    @Published private(set) var dismiss = false

    // MARK: - Private Properties
    
    @Injected(Container.analyticsManager) private var analyticsManager
    @Injected(Container.storeKitManager) private var storeKitManager
    
    private let selectedIndex = CurrentValueSubject<Int, Never>(0)
    private let purchaseSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        analyticsManager.log(event: .premiumPaywallViewed)
        
        Publishers
            .CombineLatest(storeKitManager.products, selectedIndex)
            .map { products, selectedIndex in
                products.enumerated().map { offset, product in
                    Offer(
                        product: product,
                        selected: offset == selectedIndex
                    )
                }
            }
            .assign(to: &$offers)
        
        purchaseSubject
            .withLatestFrom($offers)
            .compactMap { $0.first(where: \.selected) }
            .flatMapLatest(withUnretained: self) { strongSelf, offer in
                strongSelf.storeKitManager
                    .purchase(offer.product)
                    .ignoreFailure()
            }
            .sink(withUnretained: self) { $0.dismiss = true }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods
    
    func select(_ offer: Offer) {
        analyticsManager.log(event: .premiumSelected(id: offer.id))
        guard let index = offers.firstIndex(where: { $0.product.id == offer.product.id }) else { return }
        selectedIndex.send(index)
    }
    
    func purchaseTapped() {
        purchaseSubject.send()
    }
}
