import Factory
import GoogleMobileAds

final class GoogleAdViewModel: NSObject, ObservableObject, GADNativeAdLoaderDelegate, GADNativeAdDelegate {

    @Published var ad: GADNativeAd?
    private let adLoader: GADAdLoader

    @Injected(\.analyticsManager) private var analyticsManager

    init(unit: GoogleAdUnit) {
        adLoader = GADAdLoader(
            adUnitID: unit.identifier,
            rootViewController: nil,
            adTypes: unit.adTypes,
            options: nil
        )
        super.init()
        adLoader.delegate = self
        adLoader.load(GADRequest())
        analyticsManager.log(event: .adLoadStarted)
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