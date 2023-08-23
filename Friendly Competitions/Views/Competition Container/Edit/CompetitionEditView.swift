import ECKit
import SwiftUI

struct CompetitionEditView: View {

    @StateObject private var viewModel: CompetitionEditViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var underlyingScoringModel: UnderlyingScoringModel? = .percentOfGoals
    @State private var underlyingWorkoutType: WorkoutType? = .walking
    @State private var underlyingWorkoutMetrics = [WorkoutMetric]()
    @State private var showScoringModelsLearnMore = false

    init(competition: Competition?) {
        _viewModel = .init(wrappedValue: .init(competition: competition))
    }

    var body: some View {
        CustomList {

            CustomListSection {
                TextField("Name", text: $viewModel.name)
                    .padding(.vertical, .extraSmall)

                DatePicker(
                    L10n.Competition.Edit.starts,
                    selection: $viewModel.start,
                    in: PartialRangeFrom(min(viewModel.start, Date())),
                    displayedComponents: [.date]
                )
                DatePicker(
                    L10n.Competition.Edit.ends,
                    selection: $viewModel.end,
                    in: PartialRangeFrom(viewModel.start.addingTimeInterval(1.days)),
                    displayedComponents: [.date]
                )

                Toggle(L10n.Competition.Edit.repeats, isOn: $viewModel.repeats)
                Toggle(L10n.Competition.Edit.public, isOn: $viewModel.isPublic)
            } header: {
                Text("Details")
            }

            CustomListSection {

                HStack {
                    Text(L10n.Competition.Edit.scoringModel)
                    Spacer()
                    EnumPicker(L10n.Competition.Edit.scoringModel, selection: $underlyingScoringModel)
                }

                if underlyingScoringModel == .workout {
                    HStack {
                        Text(L10n.Competition.Edit.workoutType)
                        Spacer()
                        EnumPicker(L10n.Competition.Edit.workoutType, selection: $underlyingWorkoutType, allowsNoSelection: true)
                    }

                    if let underlyingWorkoutType {
                        MultiPicker(
                            title: L10n.Competition.Edit.workoutMetrics,
                            selection: $underlyingWorkoutMetrics,
                            options: underlyingWorkoutType.metrics
                        )
                    }
                }
            } footer: {
                Button(L10n.Competition.Edit.learnMore, toggling: $showScoringModelsLearnMore)
            }
            .sheet(isPresented: $showScoringModelsLearnMore, content: ScoringModelLearnMoreView.init)

            if viewModel.showInviteFriends {
                CustomListSection {
                    HStack {
                        NavigationLink("Invite friends") {
                            InviteView(friendRows: $viewModel.friendRows)
                        }
                        Spacer()
                        Text("\(viewModel.invitedFriendsCount) invited")
                            .foregroundColor(.secondaryLabel)
                    }
                    .padding(.vertical, .extraSmall)
                }
            }

            VStack(spacing: 15) {
                Button(action: viewModel.submitTapped) {
                    Text(viewModel.submitButtonTitle)
                        .padding(.vertical)
                        .maxWidth(.infinity)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .disabled(viewModel.submitDisabled)

                Button("Cancel", role: .destructive, action: viewModel.cancelTapped)
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .navigationTitle(viewModel.title)
        .embeddedInNavigationView()
        .onChange(of: viewModel.dismiss) { _ in dismiss() }
        .onChange(of: viewModel.scoringModel) { scoringModel in
            underlyingScoringModel = .init(scoringModel: scoringModel)
            switch scoringModel {
            case let .workout(workoutType, workoutMetrics):
                underlyingWorkoutType = workoutType
                underlyingWorkoutMetrics = workoutMetrics
            default:
                underlyingWorkoutMetrics = []
            }
        }
        .onChange(of: underlyingScoringModel) { _ in setViewModelScoringModel() }
        .onChange(of: underlyingWorkoutType) { _ in setViewModelScoringModel() }
        .onChange(of: underlyingWorkoutMetrics) { _ in setViewModelScoringModel() }
    }

    private func setViewModelScoringModel() {
        let scoringModel: Competition.ScoringModel? = {
            switch underlyingScoringModel {
            case .activityRingCloseCount:
                return .activityRingCloseCount
            case .percentOfGoals:
                return .percentOfGoals
            case .rawNumbers:
                return .rawNumbers
            case .stepCount:
                return .stepCount
            case .workout:
                guard let workoutType = underlyingWorkoutType else { return nil }
                return .workout(workoutType, underlyingWorkoutMetrics)
            case .none:
                return nil
            }
        }()
        guard let scoringModel else { return }
        viewModel.scoringModel = scoringModel
    }
}

private struct InviteView: View {

    @Binding var friendRows: [CompetitionEditViewModel.FriendRow]
    @State private var searchText = ""

    var body: some View {
        List {
            Section {
                ForEach($friendRows) { $row in
                    if searchText.isEmpty || row.user.name.localizedStandardContains(searchText) {
                        HStack {
                            Text(row.user.name)
                            Spacer()
                            if row.selected {
                                Image(systemName: .checkmark)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            row.select()
                        }
                    }
                }
            } footer: {
                if !searchText.isEmpty, friendRows.filter({ $0.user.name.localizedStandardContains(searchText) }).isEmpty {
                    Text("Nothing here")
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Invite Friends")
    }
}

enum UnderlyingScoringModel: CaseIterable, CustomStringConvertible, Hashable, Identifiable {
    case activityRingCloseCount
    case percentOfGoals
    case rawNumbers
    case stepCount
    case workout

    init(scoringModel: Competition.ScoringModel) {
        switch scoringModel {
        case .activityRingCloseCount:
            self = .activityRingCloseCount
        case .percentOfGoals:
            self = .percentOfGoals
        case .rawNumbers:
            self = .rawNumbers
        case .stepCount:
            self = .stepCount
        case .workout:
            self = .workout
        }
    }

    var id: String { description }

    var description: String {
        switch self {
        case .activityRingCloseCount:
            return L10n.Competition.ScoringModel.ActivityRingCloseCount.displayName
        case .percentOfGoals:
            return L10n.Competition.ScoringModel.PercentOfGoals.displayName
        case .rawNumbers:
            return L10n.Competition.ScoringModel.RawNumbers.displayName
        case .stepCount:
            return L10n.Competition.ScoringModel.Steps.displayName
        case .workout:
            return L10n.Competition.ScoringModel.Workout.displayName
        }
    }

    var details: String {
        switch self {
        case .activityRingCloseCount:
            return L10n.Competition.ScoringModel.ActivityRingCloseCount.description
        case .percentOfGoals:
            return L10n.Competition.ScoringModel.PercentOfGoals.description
        case .rawNumbers:
            return L10n.Competition.ScoringModel.RawNumbers.description
        case .stepCount:
            return L10n.Competition.ScoringModel.Steps.description
        case .workout:
            return L10n.Competition.ScoringModel.Workout.description
        }
    }
}

#if DEBUG
struct CompetitionEditView_Previews: PreviewProvider {

    private static func setupMocks() {
        searchManager.searchForUsersWithIDsReturnValue = .just([.andrew, .evan, .gabby])
    }

    static var previews: some View {
        CompetitionEditView(competition: nil)
            .setupMocks(setupMocks)
    }
}
#endif
