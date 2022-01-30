import HealthKitUI
import SwiftUI

struct ActivityRingView: UIViewRepresentable {

    var activitySummary: HKActivitySummary?

    func makeUIView(context: Context) -> HKActivityRingView {
        HKActivityRingView()
    }

    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        uiView.activitySummary = activitySummary
    }
}

struct ActivityRingView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityRingView(activitySummary: .mock)
    }
}
