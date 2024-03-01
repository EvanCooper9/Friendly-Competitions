import ECKit
import Factory
import GoogleMobileAds

final class GoogleAdViewModel: NSObject, ObservableObject, GADNativeAdLoaderDelegate, GADNativeAdDelegate {

    @Published var ad: GADNativeAd?
    private let adLoader: GADAdLoader

    @Injected(\.analyticsManager) private var analyticsManager: AnalyticsManaging
    @Injected(\.appState) private var appState: AppStateProviding

    private var cancellables = Cancellables()

    init(unit: GoogleAdUnit) {
        adLoader = GADAdLoader(
            adUnitID: unit.identifier,
            rootViewController: nil,
            adTypes: unit.adTypes,
            options: nil
        )
        super.init()
        adLoader.delegate = self

        appState.didBecomeActive
            .filter { $0 }
            .mapToVoid()
            .first()
            .sink { [adLoader, analyticsManager] in
                adLoader.load(GADRequest())
                analyticsManager.log(event: .adLoadStarted)
            }
            .store(in: &cancellables)
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        ad?.delegate = self
        ad = nativeAd
        analyticsManager.log(event: .adLoadSuccess)
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        analyticsManager.log(event: .adLoadError(error: error.localizedDescription))
    }

    // MARK: - GADNativeAdDelegate methods

    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        analyticsManager.log(event: .adClick)
    }

    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        analyticsManager.log(event: .adImpression)
    }
}
