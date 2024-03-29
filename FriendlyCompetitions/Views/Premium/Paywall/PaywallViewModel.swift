import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class PaywallViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published private(set) var step = PaywallStep.primer
    @Published private(set) var offers = [PaywallOffer]()
    @Published private(set) var dismiss = false
    @Published private(set) var loading = false

    // MARK: - Private Properties

    @Injected(\.analyticsManager) private var analyticsManager
    @Injected(\.premiumManager) private var premiumManager

    private let selectedIndex = CurrentValueSubject<Int, Never>(0)
    private let purchaseSubject = PassthroughSubject<Void, Never>()
    private let restoreSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        analyticsManager.log(event: .premiumPaywallPrimerViewed)

        Publishers
            .CombineLatest(premiumManager.products, selectedIndex)
            .map { products, selectedIndex in
                products.enumerated().map { offset, product in
                    PaywallOffer(
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
                strongSelf.premiumManager
                    .purchase(offer.product)
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
            }
            .sink(withUnretained: self) { $0.dismiss = true }
            .store(in: &cancellables)

        restoreSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.premiumManager
                    .restorePurchases()
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
            }
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.premiumManager.premium
                    .map(\.isNil.not)
            }
            .receive(on: RunLoop.main)
            .sink(withUnretained: self) { strongSelf, hasPremium in
                guard hasPremium else { return }
                strongSelf.dismiss = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func selectOffer(_ offer: PaywallOffer) {
        analyticsManager.log(event: .premiumSelected(id: offer.id))
        guard let index = offers.firstIndex(where: { $0.product.id == offer.product.id }) else { return }
        selectedIndex.send(index)
    }

    func nextTapped() {
        switch step {
        case .primer:
            step = .purchase
            analyticsManager.log(event: .premiumPaywallViewed)
        case .purchase:
            purchaseSubject.send()
        }
    }

    func restorePurchasesTapped() {
        restoreSubject.send()
    }
}
