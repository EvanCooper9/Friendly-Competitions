import SwiftUI
import HealthKit

struct ActivitySummaryInfoView: View {

    let activitySummary: HKActivitySummary?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading) {
                    Text("Move")
                    if let activitySummary = activitySummary?.activitySummary {
                        Text("\(activitySummary.activeEnergyBurned.formatted())/\(activitySummary.activeEnergyBurnedGoal.formatted(.number))")
                            .foregroundColor(.red)
                            .font(.title3)
                    } else {
                        Text("—").foregroundColor(.gray).font(.title3)
                    }
                }
                VStack(alignment: .leading) {
                    Text("Exercise")
                    if let activitySummary = activitySummary?.activitySummary {
                        Text("\(activitySummary.appleExerciseTime.formatted())/\(activitySummary.appleExerciseTimeGoal.formatted())")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else {
                        Text("—").foregroundColor(.gray).font(.title3)
                    }
                }
                VStack(alignment: .leading) {
                    Text("Stand")
                    if let activitySummary = activitySummary?.activitySummary {
                        Text("\(activitySummary.appleStandHours.formatted())/\(activitySummary.appleStandHoursGoal.formatted())")
                            .foregroundColor(.blue)
                            .font(.title3)
                    } else {
                        Text("—").foregroundColor(.gray).font(.title3)
                    }
                }
            }
            Spacer()
            ActivityRingView(activitySummary: activitySummary)
                .frame(width: 150, height: 150)
                .padding([.top, .bottom], 15)
        }
    }
}

struct ActivitySummaryInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitySummaryInfoView(activitySummary: ActivitySummary.mock.hkActivitySummary)
    }
}
