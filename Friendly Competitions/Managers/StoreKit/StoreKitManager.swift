import Combine
import CombineExt
import ECKit
import FirebaseCrashlytics
import FirebaseFirestoreCombineSwift
import Factory
import Foundation
import StoreKit

// sourcery: AutoMockable
protocol StoreKitManaging {
    var products: AnyPublisher<[FriendlyCompetitionsProduct], Never> { get }
    var purchases: AnyPublisher<[FriendlyCompetitionsProduct], Never> { get }
    func purchase(_ product: FriendlyCompetitionsProduct) -> AnyPublisher<Void, Error>
}

extension StoreKitManaging {
    var hasPremium: AnyPublisher<Bool, Never> {
        purchases.map(\.isNotEmpty).eraseToAnyPublisher()
    }
}

final class StoreKitManager: StoreKitManaging {
    
    enum PurchaseError: Error {
        case cancelled
    }
    
    // MARK: - Public Properties
    
    let products: AnyPublisher<[FriendlyCompetitionsProduct], Never>
    let purchases: AnyPublisher<[FriendlyCompetitionsProduct], Never>
    
    // MARK: - Private Properties
    
    @Injected(Container.analyticsManager) private var analyticsManager
    @Injected(Container.database) private var database
    @Injected(Container.userManager) private var userManager
    
    private let productsSubject = CurrentValueSubject<[FriendlyCompetitionsProduct], Never>([])
    private let purchasesSubject = CurrentValueSubject<[FriendlyCompetitionsProduct], Never>([])
    private var cancellables = Cancellables()
    
    private var transactionListener: Task<Void, Never>? = nil
    
    // MARK: - Lifecycle
    
    init() {
        products = productsSubject.eraseToAnyPublisher()
        purchases = purchasesSubject.eraseToAnyPublisher()
        Task {
            try await refreshPurchasedProducts()
        }
        listenForTransactions()
        
        database.collection("products")
            .getDocuments()
            .map(\.documents)
            .mapMany(\.documentID)
            .sink(withUnretained: self) { strongSelf, productIDs in
                Task {
                    try await strongSelf.refreshProducts(with: productIDs)
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Public Methods
    
    func purchase(_ product: FriendlyCompetitionsProduct) -> AnyPublisher<Void, Error> {
        analyticsManager.log(event: .premiumPurchaseStarted(id: product.id))
        return userManager.userPublisher
            .setFailureType(to: Error.self)
            .flatMapLatest { [weak self] user -> AnyPublisher<UUID, Error> in
                guard let strongSelf = self else { return .never() }
                if let appStoreID = user.appStoreID { return .just(appStoreID) }
                
                let id = UUID()
                var user = user
                user.appStoreID = id
                return strongSelf.userManager.update(with: user)
                    .mapToValue(id)
                    .eraseToAnyPublisher()
            }
            .flatMapAsync { [weak self] userAppStoreID in
                guard let strongSelf = self else { return }
                
                let result = try await Product.products(for: [product.id])
                    .first?
                    .purchase(options: [.appAccountToken(userAppStoreID)])
                
                switch result {
                case .success(let verificationResult):
                    switch verificationResult {
                    case .verified(let transaction):
                        // Give the user access to purchased content.
                        // Complete the transaction after providing the user access to the content.
                        strongSelf.analyticsManager.log(event: .premiumPurchased(id: product.id))
                        strongSelf.purchasesSubject.value.append(product)
                        await transaction.finish()
                    case let .unverified(transaction, verificationError):
                        // Handle unverified transactions based on your business model.
                        strongSelf.logUnverifiedTransaction(transaction, verificationError)
                    }
                case .pending:
                    // The purchase requires action from the customer.
                    // If the transaction completes, it's available through Transaction.updates.
                    strongSelf.analyticsManager.log(event: .premiumPurchasePending(id: product.id))
                case .userCancelled:
                    strongSelf.analyticsManager.log(event: .premiumPurchaseCancelled(id: product.id))
                    throw PurchaseError.cancelled
                case .none:
                    break
                @unknown default:
                    break
                }
            }
    }
    
    // MARK: - Private Methods
    
    private func refreshProducts(with productIDs: [String]) async throws {
        let products = try await Product
            .products(for: productIDs)
            .sorted(by: \.price)
            .map(FriendlyCompetitionsProduct.init)
        
        productsSubject.send(products)
    }
    
    private func refreshPurchasedProducts() async throws {
        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                // Check the type of product for the transaction and provide access to the content as appropriate.
                guard let skProduct = try await Product.products(for: [transaction.productID]).first else { return }
                purchasesSubject.value.append(.init(product: skProduct))
            case let .unverified(transaction, verificationError):
                // Handle unverified transactions based on your business model.
                logUnverifiedTransaction(transaction, verificationError)
            }
        }
    }
    
    private func listenForTransactions() {
        transactionListener = Task(priority: .background) { [weak self] in
            guard let strongSelf = self else { return }
            for await verificationResult in Transaction.updates {
                strongSelf.handle(updatedTransaction: verificationResult)
            }
        }
    }
    
    private func handle(updatedTransaction verificationResult: VerificationResult<Transaction>) {
        // Ignore unverified transactions.
        guard case .verified(let transaction) = verificationResult,
              let product = productsSubject.value.first(where: { $0.id == transaction.productID })
        else { return }
        
        if transaction.revocationDate != nil {
            // Remove access to the product identified by transaction.productID.
            // Transaction.revocationReason provides details about the revoked transaction.
            purchasesSubject.value.removeAll(where: { $0.id == product.id })
        } else if let expirationDate = transaction.expirationDate, expirationDate < Date() {
            // Do nothing, this subscription is expired.
            return
        } else if transaction.isUpgraded {
            // Do nothing, there is an active transaction for a higher level of service.
            return
        } else {
            // Provide access to the product identified by transaction.productID
            purchasesSubject.value.append(product)
        }
    }
    
    private func logUnverifiedTransaction(_ unverifiedTransaction: Transaction, _ verificationError: Error) {
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.record(exceptionModel: .init(name: "Unverified transaction", reason: unverifiedTransaction.productID))
        crashlytics.record(error: verificationError)
        crashlytics.record(error: verificationError, userInfo: [
            "productID": unverifiedTransaction.productID,
            "product": unverifiedTransaction
        ])
    }
}

private extension FriendlyCompetitionsProduct {
    init(product: Product) {
        var price = product.displayPrice
        if let subscriptionInfo = product.subscription {
            let period = subscriptionInfo.subscriptionPeriod
            var localizedPeriod: String = period.formatted(product.subscriptionPeriodFormatStyle)
            localizedPeriod = localizedPeriod.after(prefix: "one ") ?? localizedPeriod
            price += "/" + localizedPeriod
        }
        
        self.init(
            id: product.id,
            price: price,
            title: product.displayName,
            description: product.description
        )
    }
}
