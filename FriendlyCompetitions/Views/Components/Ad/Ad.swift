import Factory
import GoogleMobileAds
import SwiftUI
import UIKit

enum GoogleAdUnit: String {
    case native = "ca-app-pub-9171629407679521/4967897824"

    var adTypes: [GADAdLoaderAdType] {
        switch self {
        case .native:
            return [.native]
        }
    }
}

struct GoogleAd: View {

    let unit: GoogleAdUnit

    @State private var height: CGFloat = 0
    @State private var width: CGFloat = 0
    @StateObject private var viewModel: GoogleAdViewModel

    init(unit: GoogleAdUnit) {
        _viewModel = .init(wrappedValue: GoogleAdViewModel(unit: unit))
    }

    var body: some View {
        if let ad = viewModel.ad {
            GoogleAdWrapper(width: width, height: $height, ad: ad)
                .frame(height: height)
                .onChangeOfFrame(perform: { size in
                    width = size.width
                })
                .card(includeEdgePadding: false)
        } else {
            EmptyView()
        }
    }
}

struct GoogleAdWrapper: UIViewRepresentable {

    let width: CGFloat
    @Binding var height: CGFloat
    let ad: GADNativeAd

    func makeUIView(context: Context) -> GoogleAdUIView {
        let view = GoogleAdUIView(ad: ad)
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return view
    }

    func updateUIView(_ uiView: GoogleAdUIView, context: Context) {
        uiView.update()
        DispatchQueue.main.async {
            self.height = uiView.systemLayoutSizeFitting(CGSize(width: width, height: height)).height
            uiView.update()
        }
    }
}

final class GoogleAdUIView: UIView {

    private lazy var nativeAdView: GADNativeAdView = {
        let view = GADNativeAdView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var mediaView: GADMediaView = {
        let view = GADMediaView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var textContentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        return stackView
    }()

    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.numberOfLines = 2
        label.font = .preferredFont(forTextStyle: .title3).bold
        label.textColor = .label
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.numberOfLines = 3
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        return label
    }()

    private let ad: GADNativeAd
    private var mediaHeightConstraint: NSLayoutConstraint? {
        didSet {
            oldValue?.isActive = false
            mediaHeightConstraint?.isActive = true
        }
    }

    init(ad: GADNativeAd) {
        self.ad = ad

        super.init(frame: .zero)

        mediaView.mediaContent = ad.mediaContent
        headerLabel.text = ad.headline
        bodyLabel.text = ad.body

        configureViews()
        configureAd()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update() {
        mediaHeightConstraint = mediaView.widthAnchor.constraint(equalTo: mediaView.heightAnchor, multiplier: ad.mediaContent.aspectRatio)
    }

    private func configureViews() {
        for label in [headerLabel, bodyLabel] {
            guard let text = label.text, !text.isEmpty else { continue }
            textContentStackView.addArrangedSubview(label)
        }

        addSubview(mediaView)
        addSubview(textContentStackView)
        addSubview(nativeAdView)

        NSLayoutConstraint.activate {
            nativeAdView.topAnchor.constraint(equalTo: topAnchor)
            nativeAdView.bottomAnchor.constraint(equalTo: bottomAnchor)
            nativeAdView.leadingAnchor.constraint(equalTo: leadingAnchor)
            nativeAdView.trailingAnchor.constraint(equalTo: trailingAnchor)
        }

        NSLayoutConstraint.activate {
            mediaView.topAnchor.constraint(equalTo: topAnchor)
            mediaView.leadingAnchor.constraint(equalTo: leadingAnchor)
            mediaView.trailingAnchor.constraint(equalTo: trailingAnchor)
        }

        if textContentStackView.arrangedSubviews.isEmpty {
            mediaView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        } else {
            NSLayoutConstraint.activate {
                textContentStackView.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 10)
                textContentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
                textContentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10)
                textContentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
            }
        }

        mediaHeightConstraint = mediaView.widthAnchor.constraint(equalTo: mediaView.heightAnchor, multiplier: ad.mediaContent.aspectRatio)
    }

    private func configureAd() {
        nativeAdView.nativeAd = ad
        nativeAdView.mediaView = mediaView
        nativeAdView.headlineView = headerLabel
        nativeAdView.bodyView = bodyLabel
    }
}

@resultBuilder
struct AutoLayoutBuilder {
    static func buildBlock(_ components: NSLayoutConstraint...) -> [NSLayoutConstraint] {
        return components
    }

    static func buildArray(_ components: [[NSLayoutConstraint]]) -> [NSLayoutConstraint] {
        components.flattened()
    }
}

extension NSLayoutConstraint {
   /// Activate the layouts defined in the result builder parameter `constraints`.
   static func activate(@AutoLayoutBuilder constraints: () -> [NSLayoutConstraint]) {
       activate(constraints())
   }
}

class GoogleAdViewModel: NSObject, ObservableObject, GADNativeAdLoaderDelegate, GADNativeAdDelegate {

    @Published var ad: GADNativeAd?
    private let adLoader: GADAdLoader

    @Injected(\.analyticsManager) private var analyticsManager

    init(unit: GoogleAdUnit) {
        adLoader = GADAdLoader(
            adUnitID: unit.rawValue,
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
        ad = nativeAd
        ad?.delegate = self
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

#Preview {
    GoogleAd(unit: .native)
        .padding()
}
