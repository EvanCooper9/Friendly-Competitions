import Foundation
import StoreKit
import SwiftUI
import SwiftUIX

struct About: View {

    @StateObject private var viewModel = AboutViewModel()

    var body: some View {
        List {
            Section {
                Button(L10n.About.App.rate, systemImage: .heartFill) {
                    let windowScene = UIApplication.shared.connectedScenes
                        .filter { $0.activationState == .foregroundActive }
                        .compactMap { $0 as? UIWindowScene }
                        .first
                    guard let windowScene = windowScene else { return }
                    SKStoreReviewController.requestReview(in: windowScene)
                }
                Link(destination: .privacyPolicy) {
                    Label(L10n.About.App.privacyPolicy, systemImage: .handRaisedFill)
                }
                Link(destination: viewModel.featureRequestURL) {
                    Label(L10n.About.App.featureRequest, systemImage: .lightbulbFill)
                }
                Link(destination: viewModel.bugReportURL) {
                    Label(L10n.About.App.reportIssue, systemImage: "ladybug.fill")
                }
            } header: {
                VStack {
                    AppIcon().shadow(radius: 10)
                    Text(L10n.About.App.authoredBy)
                }
                .frame(maxWidth: .infinity)
                Text(L10n.About.App.title)
            }
            .textCase(nil)

            Section {
                Link(destination: .developer) {
                    Label(L10n.About.Developer.website, systemImage: .globeAmericasFill)
                }
            } header: {
                Text(L10n.About.Developer.title)
            }
            .textCase(nil)
        }
        .registerScreenView(name: "About")
        .navigationTitle("\(Bundle.main.name) (\(Bundle.main.version))")
        .navigationBarTitleDisplayMode(.inline)
        .embeddedInNavigationView()
    }
}

#if DEBUG
struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
    }
}
#endif
