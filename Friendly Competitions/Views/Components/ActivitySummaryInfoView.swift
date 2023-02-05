import SwiftUI

struct ActivitySummaryInfoView: View {

    let activitySummary: ActivitySummary?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading) {
                    Text(L10n.ActivitySummaryInfo.move)
                    if let activitySummary {
                        Text("\(activitySummary.activeEnergyBurned.formatted())/\(activitySummary.activeEnergyBurnedGoal.formatted(.number))")
                            .foregroundColor(.red)
                            .font(.title3)
                    } else {
                        emtpy
                    }
                }
                VStack(alignment: .leading) {
                    Text(L10n.ActivitySummaryInfo.exercise)
                    if let activitySummary {
                        Text("\(activitySummary.appleExerciseTime.formatted())/\(activitySummary.appleExerciseTimeGoal.formatted())")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else {
                        emtpy
                    }
                }
                VStack(alignment: .leading) {
                    Text(L10n.ActivitySummaryInfo.stand)
                    if let activitySummary {
                        Text("\(activitySummary.appleStandHours.formatted())/\(activitySummary.appleStandHoursGoal.formatted())")
                            .foregroundColor(.blue)
                            .font(.title3)
                    } else {
                        emtpy
                    }
                }
            }
            Spacer()
            ActivityRingView(activitySummary: activitySummary?.hkActivitySummary)
                .frame(width: 150, height: 150)
                .padding([.top, .bottom], 15)
        }
    }
    
    private var emtpy: some View {
        Text(L10n.ActivitySummaryInfo.Value.empty).foregroundColor(.gray).font(.title3)
    }
}

struct ActivitySummaryInfoView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ActivitySummaryInfoView(activitySummary: .mock)
        }
    }
}
