import Combine
import Factory
import SwiftUI

extension Banner {
    func view(file: String = #file, tapped: @escaping () -> Void, dismissed: @escaping () -> Void = {}) -> some View {
        let fileName = (file as NSString).lastPathComponent
        return BannerView(banner: self, fileName: fileName, tapped: tapped, dismissed: dismissed)
    }
}

private struct BannerView: View {

    let banner: Banner
    let fileName: String
    let tapped: () -> Void
    let dismissed: () -> Void

    @State private var horizontalOffset = CGFloat.zero
    private let targetDismissOffet = 75.0

    var body: some View {
        ZStack(alignment: .trailing) {
            Image(systemName: abs(horizontalOffset) < targetDismissOffet ? .trash : .trashFill)
                .foregroundStyle(.red)
                .padding()
                .background(Color.red.opacity(0.15))
                .background(.ultraThickMaterial)
                .clipShape(Circle())
                .opacity(horizontalOffset == .zero ? 1 : (abs(horizontalOffset) / targetDismissOffet))
            mainContent
                .offset(x: horizontalOffset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let width = gesture.translation.width
                            guard width < 0 else { return }
                            horizontalOffset = width
                        }
                        .onEnded { _ in
                            if abs(horizontalOffset) > targetDismissOffet {
                                let analyticsManager = Container.shared.analyticsManager.resolve()
                                analyticsManager.log(event: .bannerDismissed(bannerID: banner.id, file: fileName))
                                dismissed()
                            } else {
                                horizontalOffset = .zero
                            }
                        }
                )
        }
        .onAppear {
            let analyticsManager = Container.shared.analyticsManager.resolve()
            analyticsManager.log(event: .bannerViewed(bannerID: banner.id, file: fileName))
        }
        .animation(.default, value: horizontalOffset)
    }

    private var mainContent: some View {
        HStack(spacing: 10) {
            if let icon = banner.configuration.icon {
                Image(systemName: icon)
                    .foregroundColor(banner.configuration.foreground)
                    .font(.title2)
            }

            Text(banner.configuration.message)
                .font(.footnote)
                .lineLimit(2)
                .bold()
                .foregroundColor(banner.configuration.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .minimumScaleFactor(0.5)

            if let action = banner.configuration.action {
                Button(action.cta) {
                    let analyticsManager = Container.shared.analyticsManager.resolve()
                    analyticsManager.log(event: .bannerTapped(bannerID: banner.id, file: fileName))
                    tapped()
                }
                .font(.footnote)
                .bold()
                .foregroundColor(action.foreground)
                .padding(.small)
                .background(action.background)
                .cornerRadius(5)
            }
        }
        .padding(12)
        .background(banner.configuration.background)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.25), radius: 10)
    }
}

#Preview {
    BannerView(banner: .newCompetitionResults(competition: .mock), fileName: "Test", tapped: {
        print("tapped")
    }, dismissed: {
        print("dismissed")
    })
    .setupMocks()
}
