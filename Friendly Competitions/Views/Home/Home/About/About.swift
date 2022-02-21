import Foundation
import StoreKit
import SwiftUI
import UIKit

struct About: View {

    private enum Constants {
        static let iconSize = 60.0
        static var iconCornerRadius: Double { iconSize * 0.2237 }
        static let privacyPolicyURL = URL(string: "https://www.termsfeed.com/live/83fffe02-9426-43f1-94ca-aedea5df3d24")!
        static let bugReportURL = URL(string: "https://github.com/EvanCooper9/Friendly-Competitions/issues/new")!
        static let developerURL = URL(string: "https://evancooper.tech")!
    }

    var body: some View {
        List {
            Section {
                Button("Rate", systemImage: "heart") {
                    let windowScene = UIApplication.shared.connectedScenes
                        .filter { $0.activationState == .foregroundActive }
                        .compactMap { $0 as? UIWindowScene }
                        .first
                    guard let windowScene = windowScene else { return }
                    SKStoreReviewController.requestReview(in: windowScene)
                }
                Link(destination: Constants.privacyPolicyURL) {
                    Label("Privacy policy", systemImage: "hand.raised")
                }
                Button("Report an issue", systemImage: "ladybug") {
                    UIApplication.shared.open(Constants.bugReportURL)
                }
            } header: {
                VStack {
                    AppIcon()
                        .shadow(radius: 10)
                    Text("\(Bundle.main.name) (\(Bundle.main.version))")
                        .font(.title3)
                    Text("by Evan Cooper")
                }
                .frame(maxWidth: .infinity)
                Text("The app")
            }
            .textCase(nil)

            Section("The developer") {
                Link(destination: Constants.developerURL) {
                    Label("Website", systemImage: "network")
                }
            }
            .textCase(nil)
        }
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
    }
}
