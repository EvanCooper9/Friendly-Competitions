import ECKit
import SwiftUI

struct PaywallView: View {

    @StateObject private var viewModel = PaywallViewModel()
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Friendly Competitions Preimum")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Access premium features like viewing extended competition results. Viewing the latest results for each competition is free.")
                    .foregroundColor(.secondaryLabel)
            }
            .padding(.top)
            .padding()
            
            ForEach(viewModel.offers) { offer in
                
                let color: Color = offer.selected ? .accentColor : .gray.opacity(0.75)
                
                Button {
                    viewModel.select(offer)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(offer.product.title)
                                .bold()
                                .font(.callout)
                            Text(offer.product.price)
                        }
                        Spacer()
                        Circle()
                            .stroke(color, lineWidth: offer.selected ? 18 : 4)
                            .clipShape(Circle())
                            .frame(width: 25, height: 25)
                    }
                    .padding()
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color, lineWidth: 2)
                    }
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, .small)
            }
            
            Divider()
                .padding(.vertical)
            
            VStack(spacing: 20) {
                Button(action: viewModel.purchaseTapped) {
                    Text("Purchase")
                        .padding(.vertical, .small)
                        .maxWidth(.infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                
                Button("Restore Purchases", action: viewModel.restorePurchasesTapped)
            }
        }
        .withLoadingOverlay(isLoading: viewModel.loading)
        .analyticsScreen(name: "Paywall")
        .onChange(of: viewModel.dismiss) { _ in dismiss() }
        .fittedDetents()
    }
}

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
    
    private struct Preview: View {
        @State private var presented = true
        
        var body: some View {
            Button("Preview") {
                presented.toggle()
            }
            .sheet(isPresented: $presented, content: PaywallView.init)
        }
    }
    
    private static func setupMocks() {
        let products: [FriendlyCompetitionsProduct] = [
            .init(id: "1", price: "$0.99/month", title: "Monthly", description: "Access premium features for one month"),
            .init(id: "2", price: "$1.99/six months", title: "Semi-Annually", description: "Access premium features for six months"),
            .init(id: "3", price: "$2.99/year", title: "Yearly", description: "Access premium features for one year")
        ]
        storeKitManager.products = .just(products)
        storeKitManager.purchaseReturnValue = .just(())
        storeKitManager.refreshPurchasedProductsReturnValue = .just(())
    }
    
    static var previews: some View {
        Preview()
            .setupMocks(setupMocks)
    }
}
#endif
