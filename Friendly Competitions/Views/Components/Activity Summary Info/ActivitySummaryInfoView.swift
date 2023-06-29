import SwiftUI
import SwiftUIX

struct ActivitySummaryInfoView: View {

    @StateObject private var viewModel: ActivitySummaryInfoViewModel

    init(source: ActivitySummaryInfoSource) {
        _viewModel = .init(wrappedValue: .init(source: source))
    }

    var body: some View {
        HStack(spacing: 15) {
            if viewModel.loadingPermissionStatus {
                ProgressView()
                    .maxWidth(.infinity)
            } else if viewModel.shouldRequestPermissions {
                VStack(alignment: .leading) {
                    Text(L10n.ActivitySummaryInfo.MissingPermissions.message)
                        .foregroundColor(.secondaryLabel)
                    Button(L10n.ActivitySummaryInfo.MissingPermissions.cta, action: viewModel.requestPermissionsTapped)
                        .buttonStyle(.borderedProminent)
                }
            } else if viewModel.showMissingActivitySummaryText {
                VStack(alignment: .leading) {
                    Text(L10n.ActivitySummaryInfo.NotFound.message)
                        .foregroundColor(.secondaryLabel)
                    Button(L10n.ActivitySummaryInfo.NotFound.cta, action: viewModel.checkHealthAppTapped)
                        .buttonStyle(.bordered)
                }
            } else {
                textContent
            }

            Spacer()
            ActivityRingView(activitySummary: viewModel.activitySummary?.hkActivitySummary)
                .aspectRatio(1, contentMode: .fit)
                .maxHeight(150)
                .padding(.vertical, 15)
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading) {
                Text(L10n.ActivitySummaryInfo.move)
                if let activitySummary = viewModel.activitySummary {
                    Text("\(activitySummary.activeEnergyBurned.formatted())/\(activitySummary.activeEnergyBurnedGoal.formatted(.number))")
                        .activitySummaryInfoStyle(color: .red)
                } else {
                    emtpy
                }
            }
            VStack(alignment: .leading) {
                Text(L10n.ActivitySummaryInfo.exercise)
                if let activitySummary = viewModel.activitySummary {
                    Text("\(activitySummary.appleExerciseTime.formatted())/\(activitySummary.appleExerciseTimeGoal.formatted())")
                        .activitySummaryInfoStyle(color: .green)
                } else {
                    emtpy
                }
            }
            VStack(alignment: .leading) {
                Text(L10n.ActivitySummaryInfo.stand)
                if let activitySummary = viewModel.activitySummary {
                    Text("\(activitySummary.appleStandHours.formatted())/\(activitySummary.appleStandHoursGoal.formatted())")
                        .activitySummaryInfoStyle(color: .blue)
                } else {
                    emtpy
                }
            }
        }
    }

    private var emtpy: some View {
        Text(L10n.ActivitySummaryInfo.Value.empty)
            .foregroundColor(.secondaryLabel)
            .font(.title3)
    }
}

private extension Text {
    func activitySummaryInfoStyle(color: Color) -> some View {
        self.foregroundColor(color)
            .font(.title3)
            .monospaced()
    }
}

#if DEBUG
struct ActivitySummaryInfoView_Previews: PreviewProvider {

    private static func setupMocks() {
        activitySummaryManager.activitySummary = .just(nil)
        healthKitManager.shouldRequestReturnValue = .just(false)
        healthKitManager.requestReturnValue = .never()
    }

    static var previews: some View {
        ActivitySummaryInfoView(source: .local)
            .padding()
            .background(.white)
            .cornerRadius(20)
            .shadow(radius: 100)
            .padding()
            .setupMocks(setupMocks)
    }
}
#endif
