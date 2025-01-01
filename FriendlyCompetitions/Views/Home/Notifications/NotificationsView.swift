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
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .animation(.default, value: viewModel.banners)
        }
        .background(Color.listBackground.ignoresSafeArea())
        .overlay {
            if #available(iOS 17, *), viewModel.banners.isEmpty {
                ContentUnavailableView {
                    Label("Nothing here", systemImage: .bellSlash)
                } description: {
                    Text("You're all caught up")
                }
            } else if viewModel.banners.isEmpty {
                ContentUnavailableViewiOS16(
                    icon: .bellSlash,
                    title: "Nothing here",
                    message: "You're all caught up"
                )
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
import Combine

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        setupMocks {
            var banners: [Banner] = [
                .backgroundRefreshDenied,
                .healthKitDataMissing(competition: .mock, dataType: [.activeEnergy]),
                .healthKitPermissionsMissing(permissions: [.activeEnergy]),
                .newCompetitionResults(competition: .mock, resultID: .init()),
                .notificationPermissionsDenied,
                .notificationPermissionsMissing,
                .competitionResultsCalculating(competition: .mock)
            ]
            let bannersSubject = CurrentValueSubject<[Banner], Never>(banners)
            bannerManager.banners = bannersSubject.eraseToAnyPublisher()
            bannerManager.dismissedClosure = { banner in
                banners.remove(banner)
                bannersSubject.send(banners)
                return .just(())
            }
        }
        return NotificationsView()
    }
}
#endif
