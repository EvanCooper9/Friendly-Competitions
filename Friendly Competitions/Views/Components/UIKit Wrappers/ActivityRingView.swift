import HealthKitUI
import SwiftUI
import SwiftUIX

struct ActivityRingView: UIViewRepresentable {

    var activitySummary: HKActivitySummary?

    func makeUIView(context: Context) -> HKActivityRingView {
        HKActivityRingView()
    }

    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        uiView.setActivitySummary(activitySummary, animated: true)
    }
}

#if DEBUG
struct ActivityRingView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityRingView(activitySummary: .mock)
            .squareFrame()
    }
}
#endif
