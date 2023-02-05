import SwiftUI

struct PremiumBanner: View {
    
    @StateObject private var viewModel = PremiumBannerViewModel()
    
    var showPurchaseButton: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L10n.Premium.Banner.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(L10n.Premium.Banner.message)
                .font(.footnote)
            
            if showPurchaseButton {
                Button(L10n.Premium.Banner.learnMore, action: viewModel.purchaseTapped)
                    .padding(.vertical, .small)
                    .padding(.horizontal)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .buttonStyle(.plain)
            }
        }
        .padding()
        .background {
            LinearGradient(
                colors: [
                    Asset.Colors.Branded.red.swiftUIColor,
                    Asset.Colors.Branded.green.swiftUIColor,
                    Asset.Colors.Branded.blue.swiftUIColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.9)
        }
        .sheet(isPresented: $viewModel.showPaywall, content: PaywallView.init)
    }
}

#if DEBUG
struct PremiumBanner_Previews: PreviewProvider {
    static var previews: some View {
        PremiumBanner()
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.25), radius: 10)
            .padding()
    }
}
#endif
