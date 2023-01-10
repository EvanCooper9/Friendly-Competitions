import SwiftUI

struct PaywallPrimerView: View {
    var body: some View {
        VStack(spacing: 20) {
            Color.systemFill
                .aspectRatio(3/2, contentMode: .fit)
                .overlay(alignment: .top) {
                    Asset.Images.Premium.premium.swiftUIImage
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .cornerRadius(15)
            
            VStack(spacing: 8) {
                Text("Premium")
                    .font(.title)
                    .bold()
                    .maxWidth(.infinity)
                
                Text("Get instant access to all of your competition results. The latest results for all competitions are always free.")
                    .foregroundColor(.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
