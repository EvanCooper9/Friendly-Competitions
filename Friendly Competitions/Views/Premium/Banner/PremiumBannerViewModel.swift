import Combine

final class PremiumBannerViewModel: ObservableObject {

    @Published var showPaywall = false

    func purchaseTapped() {
        showPaywall.toggle()
    }
}
