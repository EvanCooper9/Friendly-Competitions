import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class PaywallViewModel: ObservableObject {
    
    struct Offer: Identifiable {
        let product: FriendlyCompetitionsProduct
        let selected: Bool
        
        var id: FriendlyCompetitionsProduct.ID { product.id }
    }

    // MARK: - Public Properties
    
    @Published private(set) var offers = [Offer]()
    @Published private(set) var loading = false
    @Published private(set) var dismiss = false

    // MARK: - Private Properties
    
    @Injected(Container.analyticsManager) private var analyticsManager
    @Injected(Container.storeKitManager) private var storeKitManager
    
    private let selectedIndex = CurrentValueSubject<Int, Never>(0)
    private let purchaseSubject = PassthroughSubject<Void, Never>()
    private let restoreSubject = PassthroughSubject<Void, Never>()

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
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
            }
            .sink(withUnretained: self) { $0.dismiss = true }
            .store(in: &cancellables)
        
        restoreSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.storeKitManager
                    .refreshPurchasedProducts()
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
            }
            .flatMapLatest(withUnretained: self) { $0.storeKitManager.hasPremium }
            .receive(on: RunLoop.main)
            .sink(withUnretained: self) { strongSelf, hasPremium in
                guard hasPremium else { return }
                strongSelf.dismiss = true
            }
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
    
    func restorePurchasesTapped() {
        restoreSubject.send()
    }
}
