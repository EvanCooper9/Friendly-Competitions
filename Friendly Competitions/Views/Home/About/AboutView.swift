import Foundation
import StoreKit
import SwiftUI
import SwiftUIX

struct AboutView: View {

    @StateObject private var viewModel = AboutViewModel()

    var body: some View {
        List {
            Section {
                Text(L10n.About.hey)
                Text(L10n.About.madeWithLove)
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
            } header: {
                VStack {
                    AppIcon().shadow(radius: 10)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, .large)
            }

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
            }
            .textCase(nil)

            Section {
                Link(destination: .developer) {
                    Label(L10n.About.Developer.website, systemImage: .globeAmericasFill)
                }
                Link(destination: .buyMeCoffee) {
                    Label(L10n.About.Developer.buyCoffee, systemImage: .cupAndSaucerFill)
                }
            }

            Section {
                ImmutableListItemView(value: "\(Bundle.main.version)", valueType: .other(systemImage: .hammerFill, description: L10n.About.App.version))
                Link(destination: .gitHub) {
                    Label(L10n.About.App.code, systemImage: .chevronLeftForwardslashChevronRight)
                        .monospaced()
                }
            } footer: {
                Text(L10n.About.App.openSource)
            }
        }
        .registerScreenView(name: "About")
        .navigationTitle(L10n.About.title)
        .navigationBarTitleDisplayMode(.inline)
        .embeddedInNavigationView()
    }
}

#if DEBUG
struct About_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
            .setupMocks()
    }
}
#endif
