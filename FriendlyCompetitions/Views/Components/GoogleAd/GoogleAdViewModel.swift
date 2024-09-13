import Combine
import CombineSchedulers
import ECKit
import Factory
import FCKit
import Foundation
import GoogleMobileAds

final class GoogleAdViewModel: NSObject, ObservableObject, GADNativeAdLoaderDelegate, GADNativeAdDelegate {

    @Published var ad: GADNativeAd?

    // MARK: - Private Properties

    @Injected(\.analyticsManager) private var analyticsManager: AnalyticsManaging
    @Injected(\.appState) private var appState: AppStateProviding
    @Injected(\.scheduler) private var scheduler: AnySchedulerOf<RunLoop>

    private let adLoader: GADAdLoader
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(unit: GoogleAdUnit) {
        let nativeOptions = GADNativeAdMediaAdLoaderOptions()
        nativeOptions.mediaAspectRatio = .landscape

        adLoader = GADAdLoader(
            adUnitID: unit.identifier,
            rootViewController: nil,
            adTypes: unit.adTypes,
            options: [nativeOptions]
        )
        super.init()

        adLoader.delegate = self

        Task { [adLoader, analyticsManager] in
            adLoader.load(GADRequest())
            analyticsManager.log(event: .adLoadStarted)
        }
    }

    // MARK: - GADNativeAdLoaderDelegate

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        ad?.delegate = self
        ad = nativeAd
        analyticsManager.log(event: .adLoadSuccess)
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        analyticsManager.log(event: .adLoadError(error: error.localizedDescription))
    }

    // MARK: - GADNativeAdDelegate

    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        analyticsManager.log(event: .adClick)
    }

    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        analyticsManager.log(event: .adImpression)
    }
}
