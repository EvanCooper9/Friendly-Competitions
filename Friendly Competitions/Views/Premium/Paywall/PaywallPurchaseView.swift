import ECKit
import SwiftUI

struct PaywallPurchaseView: View {

    let offers: [PaywallOffer]
    let selectOffer: (PaywallOffer) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Premium")
                .font(.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(offers) { offer in
                let color: Color = offer.selected ? .accentColor : .gray.opacity(0.25)
                Button {
                    selectOffer(offer)
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(offer.product.title)
                                .bold()
                            Spacer()
                            Circle()
                                .stroke(color, lineWidth: offer.selected ? 18 : 4)
                                .clipShape(Circle())
                                .frame(width: 25, height: 25)
                        }
                        Text(offer.product.price)
                            .font(.title2)
                        HStack {
                            if let offer = offer.product.offer {
                                Chip(text: offer, color: .green)
                            }
                            Text("Auto-renews. Cancel Anytime.")
                                .foregroundColor(.secondaryLabel)
                                .font(.caption)
                        }
                    }
                    .padding(12)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color, lineWidth: 2)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

struct Chip: View {

    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .bold()
            .foregroundColor(color)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(color.opacity(0.05))
            .cornerRadius(5)
    }
}
