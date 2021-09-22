import HealthKitUI
import SwiftUI

struct ActivityRingView: UIViewRepresentable {

    @Binding var activitySummary: HKActivitySummary?

    func makeUIView(context: Context) -> HKActivityRingView {
        HKActivityRingView()
    }

    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        uiView.activitySummary = activitySummary
    }
}
