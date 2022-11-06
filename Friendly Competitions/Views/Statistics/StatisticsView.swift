import ECKit
import SwiftUI
import SwiftUIX

struct StatisticsView: View {

    @StateObject private var viewModel = StatisticsViewModel()

    var body: some View {
        Group {
            if viewModel.showPaywall {
                StatisticsPaywallView()
            } else {
                Text("Statistics")
            }
        }
        .navigationTitle("Statistics")
    }
}

#if DEBUG
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .setupMocks()
    }
}
#endif
