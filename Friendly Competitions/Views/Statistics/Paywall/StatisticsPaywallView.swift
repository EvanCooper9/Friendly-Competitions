import Charts
import ECKit
import SwiftUI
import SwiftUIX

struct StatisticsPaywallView: View {

    @StateObject private var viewModel = StatisticsPaywallViewModel()
    

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Keep track of your activity over time with statistics. Checkout some sample charts below.")
                    .foregroundColor(.secondaryLabel)
                
                let sampleData = [
                    (title: "Points", data: [1200.0, 3000, 2000, 1500, 2000, 1300], color: Color.green),
                    (title: "Rankings", data: [1.0, 3, 2, 5, 2, 1], color: .red),
                    (title: "Closing rings", data: [1.0, 1.1, 0.2, 0.8, 2.2, 1.8], color: .blue)
                ]
                
                ForEach(sampleData, id: \.title) { sampleData in
                    Card(alignment: .leading) {
                        Text(sampleData.title)
                            .bold()
                            .font(.title3)
                        
                        sampleChart(with: sampleData.data)
                            .foregroundColor(sampleData.color)
                    }
                }
                
                Button(action: viewModel.purchaseTapped) {
                    Text("Purchase for $0.99")
                        .padding()
                        .maxWidth(.infinity)
                        .foregroundColor(.white)
                        .background(.accentColor)
                        .cornerRadius(10)
                }
                
                Text("Proceeds go towards project maintenance.")
                    .font(.caption)
                    .foregroundColor(.secondaryLabel)
                    .padding(.bottom)
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func sampleChart(with data: [Double]) -> some View {
        if #available(iOS 16, *) {
            Chart {
                ForEach(0..<data.count, id: \.self) { index in
                    let timeInterval: TimeInterval = 1.days
                    let date = Date.now.advanced(by: timeInterval * Double(-index))
                    PointMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Completion", data[index])
                    )
                    LineMark(
                        x: .value("Date", date, unit: .day),
                        y: .value("Completion", data[index])
                    )
                    .interpolationMethod(.cardinal)
                }
            }
            .aspectRatio(3, contentMode: .fit)
        }
    }
}

#if DEBUG
struct StatisticsPaywallView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsPaywallView()
            .setupMocks()
            .navigationTitle("Statistics")
            .embeddedInNavigationView()
    }
}
#endif
