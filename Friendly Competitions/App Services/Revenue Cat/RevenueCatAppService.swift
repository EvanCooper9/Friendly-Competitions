import RevenueCat
import UIKit

final class RevenueCatAppService: AppService {
    func didFinishLaunching() {
        let apiKey: String
        #if DEBUG
        apiKey = "appl_REFBiyXbqcpKtUtawSUJezooOfQ"
        #else
        apiKey = "appl_PfCzNKLwrBPhZHDqVcrFOfigEHq"
        #endif
        Purchases.logLevel = .warn
        Purchases.configure(with: .init(withAPIKey: apiKey).with(usesStoreKit2IfAvailable: true))
    }
}
