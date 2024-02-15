import ECKit
import GoogleMobileAds
import SwiftUI
import UIKit

struct GoogleAd: View {

    @State private var height: CGFloat = 0
    @State private var width: CGFloat = 0
    @StateObject private var viewModel: GoogleAdViewModel

    init(unit: GoogleAdUnit) {
        _viewModel = .init(wrappedValue: GoogleAdViewModel(unit: unit))
    }

    var body: some View {
        if let ad = viewModel.ad {
            GoogleAdWrapper(width: width, height: $height, ad: ad)
                .frame(minHeight: height)
                .onChangeOfFrame(perform: { size in
                    width = size.width
                })
                .card(includeEdgePadding: false)
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
        DispatchQueue.main.async {
            height = uiView.height(for: width)
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
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .title3).bold
        label.textColor = .label
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        return label
    }()

    private lazy var adChoicesView: UIView = {
        let view = GADAdChoicesView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let ad: GADNativeAd

    private var mediaAspectRatio: CGFloat {
        let adAspectRatio = ad.mediaContent.aspectRatio
        if adAspectRatio > 0 {
            return adAspectRatio
        } else {
            print("Bad ad aspect ratio", adAspectRatio)
            return 16.0 / 9.0
        }
    }

    init(ad: GADNativeAd) {
        self.ad = ad
        super.init(frame: .zero)
        clipsToBounds = false

        configureViews()

        // configure GADNativeAdView
        nativeAdView.nativeAd = ad
        nativeAdView.mediaView = mediaView
        nativeAdView.headlineView = headerLabel
        nativeAdView.bodyView = bodyLabel

        // configure ad content
        mediaView.mediaContent = ad.mediaContent
        headerLabel.text = ad.headline
        bodyLabel.text = ad.body
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func height(for width: CGFloat) -> CGFloat {
        let minSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        return systemLayoutSizeFitting(minSize,
                                       withHorizontalFittingPriority: .required,
                                       verticalFittingPriority: .fittingSizeLevel).height
    }

    private func configureViews() {
        addSubview(nativeAdView)
        NSLayoutConstraint.activate {
            nativeAdView.topAnchor.constraint(equalTo: topAnchor, constant: 1)
            nativeAdView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1)
            nativeAdView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1)
            nativeAdView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1)
        }

        nativeAdView.addSubview(mediaView)
        NSLayoutConstraint.activate {
            mediaView.topAnchor.constraint(equalTo: nativeAdView.topAnchor)
            mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor)
            mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor)
        }
        mediaView.widthAnchor.constraint(equalTo: mediaView.heightAnchor, multiplier: mediaAspectRatio).isActive = true

        if ad.headline != nil || ad.body != nil {
            nativeAdView.addSubview(textContentStackView)
            if ad.headline != nil {
                textContentStackView.addArrangedSubview(headerLabel)
            }
            if ad.body != nil {
                textContentStackView.addArrangedSubview(bodyLabel)
            }
            NSLayoutConstraint.activate {
                textContentStackView.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 10)
                textContentStackView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -10)
                textContentStackView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 10)
                textContentStackView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -10)
            }
        } else {
            mediaView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor).isActive = true
        }

        nativeAdView.addSubview(adChoicesView)
        NSLayoutConstraint.activate {
            adChoicesView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor)
            adChoicesView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor)
        }
    }
}

#if DEBUG
struct GoogleAd_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Google Ad")
            GoogleAd(unit: .native)
                .padding()
        }
    }
}
#endif
