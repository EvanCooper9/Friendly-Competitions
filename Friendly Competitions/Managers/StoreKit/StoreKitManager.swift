import Combine
import CombineExt
import Factory
import Foundation
import StoreKit

// sourcery: AutoMockable
protocol StoreKitManaging {
    var purchases: AnyPublisher<[FriendlyCompetitionsProduct], Never> { get }
    func purchase(_ product: FriendlyCompetitionsProduct) -> AnyPublisher<Void, Error>
}

final class StoreKitManager: StoreKitManaging {
    
    // MARK: - Public Properties
    
    let purchases: AnyPublisher<[FriendlyCompetitionsProduct], Never>
    
    // MARK: - Private Properties
    
    @Injected(Container.userManager) private var userManager
    
    private let purchasesSubject = CurrentValueSubject<[FriendlyCompetitionsProduct], Never>([])
    
    private var transactionListener: Task<Void, Never>? = nil
    
    // MARK: - Lifecycle
    
    init() {
        purchases = purchasesSubject.eraseToAnyPublisher()
        Task {
            await refreshPurchasedProducts()
        }
        listenForTransactions()
    }
    
    // MARK: - Public Methods
    
    func purchase(_ product: FriendlyCompetitionsProduct) -> AnyPublisher<Void, Error> {
        let user = userManager.user
        // TODO: set the account token on user
        
        let subject = PassthroughSubject<Void, Error>()
        Task {
            do {
                let products = try await Product.products(for: [product.rawValue])
                let result = try await products.first?.purchase()
                switch result {
                case .success(let verificationResult):
                    switch verificationResult {
                    case .verified(let transaction):
                        // Give the user access to purchased content.
                        // Complete the transaction after providing
                        // the user access to the content.
                        await transaction.finish()
                        purchasesSubject.append([product])
                    case .unverified(let transaction, let verificationError):
                        // Handle unverified transactions based
                        // on your business model.
                        break
                    }
                case .pending:
                    // The purchase requires action from the customer.
                    // If the transaction completes,
                    // it's available through Transaction.updates.
                    break
                case .userCancelled:
                    // The user canceled the purchase.
                    break
                case .none:
                    break
                @unknown default:
                    break
                }
                subject.send(())
                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func refreshPurchasedProducts() async {
        var purchases = [FriendlyCompetitionsProduct]()
        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                // Check the type of product for the transaction
                // and provide access to the content as appropriate.
                guard let product = FriendlyCompetitionsProduct(rawValue: transaction.productID) else { return }
                purchases.append(product)
            case .unverified(let unverifiedTransaction, let verificationError):
                // Handle unverified transactions based on your
                // business model.
                print("Unverified transaction:")
                print("  ", unverifiedTransaction.productID)
                print("  ", verificationError)
                print("  ", verificationError.localizedDescription)
                break
            }
        }
        purchasesSubject.send(purchases)
    }
    
    private func listenForTransactions() {
        transactionListener = Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                self.handle(updatedTransaction: verificationResult)
            }
        }
    }
    
    private func handle(updatedTransaction verificationResult: VerificationResult<Transaction>) {
        guard case .verified(let transaction) = verificationResult else {
            // Ignore unverified transactions.
            return
        }

        if let revocationDate = transaction.revocationDate {
            // Remove access to the product identified by transaction.productID.
            // Transaction.revocationReason provides details about
            // the revoked transaction.
        } else if let expirationDate = transaction.expirationDate,
            expirationDate < Date() {
            // Do nothing, this subscription is expired.
            return
        } else if transaction.isUpgraded {
            // Do nothing, there is an active transaction
            // for a higher level of service.
            return
        } else {
            // Provide access to the product identified by
            // transaction.productID.
        }
    }
}
