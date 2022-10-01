import Foundation
import StoreKit
import SwiftUI
import SwiftUIX

struct About: View {

    private enum Constants {
        static let privacyPolicyURL = URL(string: "https://www.termsfeed.com/live/83fffe02-9426-43f1-94ca-aedea5df3d24")!
        static let bugReportURL = URL(string: "https://www.reddit.com/r/friendlycompetitions/submit?title=Bug%20Report")!
        static let featureRequestURL = URL(string: "https://www.reddit.com/r/friendlycompetitions/submit?title=Feature%20Request")!
        static let developerURL = URL(string: "https://evancooper.tech")!
    }

    var body: some View {
        List {
            Section {
                Button("Rate", systemImage: .heartFill) {
                    let windowScene = UIApplication.shared.connectedScenes
                        .filter { $0.activationState == .foregroundActive }
                        .compactMap { $0 as? UIWindowScene }
                        .first
                    guard let windowScene = windowScene else { return }
                    SKStoreReviewController.requestReview(in: windowScene)
                }
                Link(destination: Constants.privacyPolicyURL) {
                    Label("Privacy policy", systemImage: .handRaisedFill)
                }
                Link(destination: Constants.featureRequestURL) {
                    Label("Feature request", systemImage: .lightbulbFill)
                }
                Link(destination: Constants.bugReportURL) {
                    Label("Report an issue", systemImage: "ladybug.fill")
                }
            } header: {
                VStack {
                    AppIcon().shadow(radius: 10)
                    Text("by Evan Cooper")
                }
                .frame(maxWidth: .infinity)
                Text("The App")
            }
            .textCase(nil)

            Section("The Developer") {
                Link(destination: Constants.developerURL) {
                    Label("Website", systemImage: .globeAmericasFill)
                }
            }
            .textCase(nil)
        }
        .registerScreenView(name: "About")
        .navigationTitle("\(Bundle.main.name) (\(Bundle.main.version))")
        .navigationBarTitleDisplayMode(.inline)
        .embeddedInNavigationView()
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
    }
}
