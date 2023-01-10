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
                        Text("Continue")
                        Image(systemName: .chevronRight)
                    }
                    .padding(.vertical, .small)
                    .padding(.horizontal)
                    .background(.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                
                Button("Restore Purchases", action: viewModel.restorePurchasesTapped)
                
                HStack(spacing: 4) {
                    Link("Terms of Service", destination: .termsOfService)
                    Text("&").foregroundColor(.secondaryLabel)
                    Link("Privacy Policy", destination: .privacyPolicy)
                }
                .font(.caption)
            }
        }
        .withLoadingOverlay(isLoading: viewModel.loading)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: viewModel.step) { _ in size = proxy.size }
                    .onAppear { size = proxy.size }
            }
        }
        .presentationDetents(detents)
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
    
    static var previews: some View {
        Preview()
            .setupMocks()
    }
}
#endif
