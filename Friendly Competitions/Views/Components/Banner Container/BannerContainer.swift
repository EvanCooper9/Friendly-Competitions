import SwiftUI
import SwiftUIX

struct BannerContainer<Content: View>: View {

    @StateObject private var viewModel = BannerContainerViewModel()

    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            if let banner = viewModel.banner {
                banner.view(viewModel.tapped)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .maxWidth(.infinity)
                    .background(banner.configuration.background)
            }

            content()
                .maxHeight(.infinity)
        }
        .animation(.default, value: viewModel.banner)
    }
}

#if DEBUG
import Combine

struct BannerContainer_Previews: PreviewProvider {

    private static func setupMocks() {
        bannerManager.banner = .just(.missingCompetitionData)
//        bannerManager.banner = .just(.missingCompetitionPermissions)
    }

    static var previews: some View {
        BannerContainer {
            Text("Test content")
        }
        .setupMocks(setupMocks)
    }
}
#endif
