import Foundation
import StoreKit
import SwiftUI
import UIKit

struct About: View {

    private enum Constants {
        static let iconSize = 60.0
        static var iconCornerRadius: Double { iconSize * 0.2237 }
        static let privacyPolicyURL = URL(string: "https://www.termsfeed.com/live/83fffe02-9426-43f1-94ca-aedea5df3d24")!
        static let developerURL = URL(string: "https://evancooper.tech")!
    }

    var body: some View {
        List {
            Section {
                Button {
                    guard let windowScene = UIApplication.shared.windows.first?.windowScene else { return }
                    SKStoreReviewController.requestReview(in: windowScene)
                } label: {
                    Label("Rate", systemImage: "heart")
                }
                Link(destination: Constants.privacyPolicyURL) {
                    Label("Privacy policy", systemImage: "hand.raised")
                }
            } header: {
                VStack {
                    Image(uiImage: Bundle.main.icon)
                        .resizable()
                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                        .cornerRadius(Constants.iconCornerRadius)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .shadow(radius: 10)
                    Text("\(Bundle.main.name) (\(Bundle.main.version))")
                        .font(.title3)
                    Text("by Evan Cooper")
                }
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
