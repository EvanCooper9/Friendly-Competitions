import Combine
import CombineExt
import ECKit
import FirebaseCrashlytics
import FirebaseFirestoreCombineSwift
import Factory
import Foundation
import RevenueCat
import StoreKit
import UIKit

// sourcery: AutoMockable
protocol PremiumManaging {
    var premium: AnyPublisher<Premium?, Never> { get }
    var products: AnyPublisher<[Product], Never> { get }
    
    func purchase(_ product: Product) -> AnyPublisher<Void, Error>
    func restorePurchases() -> AnyPublisher<Void, Error>
    func manageSubscription()
}

final class PremiumManager: PremiumManaging {
    
    enum PurchaseError: Error {
        case cancelled
    }
    
    // MARK: - Public Properties
    
    let premium: AnyPublisher<Premium?, Never>
    let products: AnyPublisher<[Product], Never>
    
    // MARK: - Private Properties
    
    @Injected(Container.analyticsManager) private var analyticsManager
    @Injected(Container.database) private var database
    @Injected(Container.userManager) private var userManager
    
    private let premiumSubject = ReplaySubject<Premium?, Never>(bufferSize: 1)
    private let productsSubject = ReplaySubject<[Product], Never>(bufferSize: 1)
    private var cancellables = Cancellables()
    
    private let entitlementIdentifier = "Premium"
    private var currentOffering: Offering?
    private var customerInfoTask: Task<Void, Error>?
    
    // MARK: - Lifecycle
    
    init() {
        premium = premiumSubject.eraseToAnyPublisher()
        products = productsSubject.eraseToAnyPublisher()
        
        login()
            .subscribe(on: DispatchQueue.global(qos: .background))
            .flatMapLatest(withUnretained: self) { $0.fetchStore() }
            .flatMapLatest(withUnretained: self) { $0.restorePurchases() }
            .sink()
            .store(in: &cancellables)
        
        premiumSubject
            .unwrap()
            .compactMap { premium in
                guard let expiry = premium.expiry else { return nil }
                let secondsUntilExpiry = expiry.timeIntervalSince(.now)
                guard secondsUntilExpiry > 0 else { return nil }
                return secondsUntilExpiry
            }
            .setFailureType(to: Error.self)
            .flatMapLatest { (secondsUntilExpiry: TimeInterval) -> AnyPublisher<Void, Error> in
                Timer.publish(every: secondsUntilExpiry, on: .main, in: .common)
                    .autoconnect()
                    .first()
                    .setFailureType(to: Error.self)
                    .mapToVoid()
                    .eraseToAnyPublisher()
            }
            .flatMapLatest(withUnretained: self) { $0.restorePurchases() }
            .sink()
            .store(in: &cancellables)
        
//        customerInfoTask = .init { [weak self] in
//            for try await _ in Purchases.shared.customerInfoStream { [weak self] in
//                guard let strongSelf = self else { return }
//                strongSelf.restorePurchases()
//                    .sink()
//                    .store(in: &strongSelf.cancellables)
//            }
//        }
    }
    
    // MARK: - Public Methods
    
    func purchase(_ product: Product) -> AnyPublisher<Void, Error> {
        analyticsManager.log(event: .premiumPurchaseStarted(id: product.id))
        guard let package = currentOffering?.package(identifier: product.id) else { return .just(()) }
        let subject = PassthroughSubject<Void, Error>()
        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, cancelled in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard !cancelled else {
                self?.analyticsManager.log(event: .premiumPurchaseCancelled(id: product.id))
                subject.send(completion: .failure(PurchaseError.cancelled))
                return
            }
            
            guard let strongSelf = self else { return }
            let entitlement = customerInfo?.entitlements[strongSelf.entitlementIdentifier]
            let premium = Premium(
                id: product.id,
                title: product.title,
                price: product.price,
                renews: entitlement?.willRenew ?? false,
                expiry: entitlement?.expirationDate
            )
            strongSelf.analyticsManager.log(event: .premiumPurchased(id: premium.id))
            strongSelf.premiumSubject.send(premium)
            subject.send()
            subject.send(completion: .finished)
        }
        return subject.eraseToAnyPublisher()
    }
    
    func restorePurchases() -> AnyPublisher<Void, Error> {
        let subject = PassthroughSubject<Void, Error>()
        
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            if let error {
                self?.premiumSubject.send(nil)
                subject.send(completion: .failure(error))
                return
            }
            
            guard let strongSelf = self,
                  let entitlement = customerInfo?.entitlements[strongSelf.entitlementIdentifier],
                  entitlement.isActive,
                  let package = strongSelf.currentOffering?.availablePackages.first(where: { $0.storeProduct.productIdentifier == entitlement.productIdentifier })
            else {
                self?.premiumSubject.send(nil)
                subject.send()
                subject.send(completion: .finished)
                return
            }
            
            let premium = Premium(
                id: package.storeProduct.productIdentifier,
                title: package.storeProduct.localizedTitle,
                price: package.localizedPriceWithUnit,
                renews: entitlement.willRenew,
                expiry: entitlement.expirationDate
            )
            
            strongSelf.premiumSubject.send(premium)
            subject.send()
            subject.send(completion: .finished)
        }
        return subject.eraseToAnyPublisher()
    }
    
    func manageSubscription() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        Task {
            try await AppStore.showManageSubscriptions(in: windowScene)
        }
    }
    
    // MARK: - Private Methods
    
    private func login() -> AnyPublisher<Void, Error> {
        let subject = PassthroughSubject<Void, Error>()
        Purchases.shared.logIn(userManager.user.id) { customerInfo, created, error in
            if let error {
                subject.send(completion: .failure(error))
                return
            }
            subject.send()
            subject.send(completion: .finished)
        }
        return subject.eraseToAnyPublisher()
    }
    
    private func fetchStore() -> AnyPublisher<Void, Error> {
        let subject = PassthroughSubject<Void, Error>()
        Purchases.shared.getOfferings { [weak self] offerings, error in
            if let error {
                subject.send(completion: .failure(error))
                return
            }
            guard let strongSelf = self else {
                subject.send()
                subject.send(completion: .finished)
                return
            }
            strongSelf.currentOffering = offerings?.current
            guard let packages = offerings?.current?.availablePackages else {
                subject.send()
                subject.send(completion: .finished)
                return
            }
            
            let productIDs = packages.map(\.storeProduct.productIdentifier)
            Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIDs) { result in
                let products = packages.map { package in
                    var offer: String?
                    switch result[package.storeProduct.productIdentifier]?.status {
                    case .eligible:
                        offer = package.storeProduct.introductoryDiscount?.localizedDescription
                    default:
                        break
                    }
                    
                    return Product(
                        id: package.identifier,
                        price: package.localizedPriceWithUnit,
                        offer: offer,
                        title: package.storeProduct.localizedTitle,
                        description: package.storeProduct.localizedDescription
                    )
                }
                
                strongSelf.productsSubject.send(products)
                subject.send()
                subject.send(completion: .finished)
            }
        }
        return subject.eraseToAnyPublisher()
    }
}

private extension Package {
    var localizedPriceWithUnit: String {
        guard let subscriptionPeriod = storeProduct.subscriptionPeriod else { return localizedPriceString }
        return "\(localizedPriceString) / \(subscriptionPeriod.value) \(subscriptionPeriod.unit.localizedDescription)\(subscriptionPeriod.value != 1 ? "s" : "")"
    }
}

private extension StoreProductDiscount {
    var localizedDescription: String {
        let period = subscriptionPeriod
        let price = price == 0 ? "Free" : localizedPriceString
        var duration = "\(period.value) \(period.unit.localizedDescription)"
        if period.value != 1 {
            duration += "s"
        }
        return "\(price) for \(duration)"
    }
}

private extension SubscriptionPeriod.Unit {
    var localizedDescription: String {
        switch self {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        }
    }
}
