import Foundation
import StoreKit
import SwiftUI
import SwiftUIX

struct About: View {
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
                Link(destination: .privacyPolicy) {
                    Label("Privacy policy", systemImage: .handRaisedFill)
                }
                Link(destination: .featureRequest) {
                    Label("Feature request", systemImage: .lightbulbFill)
                }
                Link(destination: .bugReport) {
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
                Link(destination: .developer) {
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
