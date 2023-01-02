import Factory
import Foundation
import StoreKit

// sourcery: AutoMockable
protocol StoreKitManaging {
//    var products: [Product] { get }
}

final class StoreKitManager: StoreKitManaging {
    
    // MARK: - Public Properties
    
    private(set) var products: [Product] = []
    
    // MARK: - Private Properties
    
    @Injected(Container.userManager) private var userManager
    
    private var transactionListener: Task<Void, Never>? = nil
    
    // MARK: - Lifecycle
    
    init() {
        listenForTransactions()
        fetchProducts()
    }
    
    // MARK: - Public Methods
    
    func purchase(_ product: Product) {
        let user = userManager.user
        // TODO: set the account token on user
        
        Task {
//            try await product.purchase(options: [.appAccountToken(userID)])
            try await product.purchase()
        }
    }
    
    // MARK: - Private Methods
    
    private func refreshPurchasedProducts() async {
        // Iterate through the user's purchased products.
//        for await verificationResult in Transaction.currentEntitlements {
//            switch verificationResult {
//            case .verified(let transaction):
                // Check the type of product for the transaction
                // and provide access to the content as appropriate.
//            case .unverified(let unverifiedTransaction, let verificationError):
                // Handle unverified transactions based on your
                // business model.
//            }
//        }
    }
    
    private func listenForTransactions() {
        transactionListener = Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                self.handle(updatedTransaction: verificationResult)
            }
        }
    }
    
    private func fetchProducts() {
        Task(priority: .background) { [weak self] in
            self?.products = try await Product.products(for: ["com.evancooper.competition-history"])
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
