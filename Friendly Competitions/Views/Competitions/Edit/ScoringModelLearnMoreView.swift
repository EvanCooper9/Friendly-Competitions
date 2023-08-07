import SwiftUI

struct ScoringModelLearnMoreView: View {
    var body: some View {
        List {
            ForEach(UnderlyingScoringModel.allCases, id: \.description) { scoringModel in
                VStack(alignment: .leading) {
                    Text(scoringModel.description)
                    Text(scoringModel.details)
                        .foregroundColor(.secondaryLabel)

                    if scoringModel == .workout {
                        VStack(alignment: .leading) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text("Workout types")
                                    ForEach(WorkoutType.allCases) { workoutType in
                                        Text("• \(workoutType.description)")
                                    }
                                    .foregroundColor(.secondaryLabel)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                VStack(alignment: .leading) {
                                    Text("Workout metrics")
                                    ForEach(WorkoutMetric.allCases) { metric in
                                        Text("• \(metric.description)")
                                    }
                                    .foregroundColor(.secondaryLabel)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.top)
                    }
                }
            }
        }
        .navigationTitle(L10n.Competition.Edit.scoringModel)
        .embeddedInNavigationView()
    }
}
