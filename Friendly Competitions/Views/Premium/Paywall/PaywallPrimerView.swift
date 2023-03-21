import SwiftUI

struct PaywallPrimerView: View {
    var body: some View {
        VStack(spacing: 20) {
            Color.systemFill
                .aspectRatio(3/2, contentMode: .fit)
                .overlay(alignment: .top) {
                    Asset.Images.premium.swiftUIImage
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .cornerRadius(15)

            VStack(spacing: 8) {
                Text(L10n.Premium.Primer.title)
                    .font(.title)
                    .bold()
                    .maxWidth(.infinity)

                Text(L10n.Premium.Primer.message)
                    .foregroundColor(.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
