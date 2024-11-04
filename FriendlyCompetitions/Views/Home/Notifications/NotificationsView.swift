import ECKit
import SwiftUI
import SwiftUIX

struct NotificationsView: View {

    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(viewModel.banners) { banner in
                    Swipeable {
                        banner.view {
                            viewModel.tapped(banner)
                        }
                    } onDelete: {
                        viewModel.dismissed(banner)
                    }
                    .transition(.move(edge: .leading))
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.listBackground.ignoresSafeArea())
        .overlay {
            if #available(iOS 17, *), viewModel.banners.isEmpty {
                ContentUnavailableView {
                    Label("Nothing here", systemImage: .bellSlash)
                } description: {
                    Text("You're all caught up")
                }
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            Menu {
                Button("Reset dismissed banners", action: viewModel.reset)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .embeddedInNavigationView()
        .onChange(of: viewModel.dismiss) { _ in dismiss() }
    }
}

#if DEBUG
struct NotificationsView_Previews: PreviewProvider {

    private static func setupMocks() {
        bannerManager.banners = .just([.backgroundRefreshDenied, .competitionResultsCalculating(competition: .mock)])
    }

    static var previews: some View {
        NotificationsView()
            .setupMocks(setupMocks)
    }
}
#endif
