import SwiftUI

struct PaywallView: View {

    @StateObject private var viewModel = PaywallViewModel()

    @State private var size: CGSize?
    private var detents: Set<PresentationDetent> {
        guard let size else { return [.large] }
        return [.height(size.height)]
    }

    var body: some View {
        VStack(spacing: 20) {
            switch viewModel.step {
            case .primer:
                PaywallPrimerView()
            case .purchase:
                PaywallPurchaseView(
                    offers: viewModel.offers,
                    selectOffer: viewModel.selectOffer
                )
            }

            Divider()

            VStack(spacing: 15) {
                Button(action: viewModel.nextTapped) {
                    HStack {
                        Text(L10n.Generics.continue)
                        Image(systemName: .chevronRight)
                    }
                    .padding(.vertical, .small)
                    .padding(.horizontal)
                    .background(.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }

                Button(L10n.Premium.Paywall.restore, action: viewModel.restorePurchasesTapped)

                HStack(spacing: 4) {
                    Link(L10n.Premium.Paywall.tos, destination: .termsOfService)
                    Text(L10n.Generics.Symbols.apersand).foregroundColor(.secondaryLabel)
                    Link(L10n.Premium.Paywall.pp, destination: .privacyPolicy)
                }
                .font(.caption)
            }
        }
        .withLoadingOverlay(isLoading: viewModel.loading)
        .fittedDetents()
        .animation(.default, value: detents)
    }
}

#if DEBUG
struct PaywallView_Previews: PreviewProvider {

    private struct Preview: View {
        @State private var showPaywall = true
        var body: some View {
            Button("Show Paywall", toggle: $showPaywall)
                .sheet(isPresented: $showPaywall, content: PaywallView.init)
        }
    }

    private static func setupMocks() {
        let products: [Product] = [
            .init(id: "1", price: "$0.99 / month", offer: "Free for 3 days", title: "Monthly", description: "Access premium features for one month"),
            .init(id: "2", price: "$1.99 / six months", offer: nil, title: "Semi-Annually", description: "Access premium features for six months"),
            .init(id: "3", price: "$2.99 / year", offer: nil, title: "Yearly", description: "Access premium features for one year")
        ]
        premiumManager.products = .just(products)
    }

    static var previews: some View {
        Preview()
            .setupMocks(setupMocks)
    }
}
#endif
