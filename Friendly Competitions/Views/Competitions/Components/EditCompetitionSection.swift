import ECKit
import SwiftUI
import SwiftUIX

struct EditCompetitionSection: View {

    private enum UnderlyingScoringModel: CaseIterable, CustomStringConvertible, Hashable, Identifiable {
        case activityRingCloseCount
        case percentOfGoals
        case rawNumbers
        case stepCount
        case workout

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

    // MARK: - Public Properties

    @Binding var name: String
    @Binding var scoringModel: Competition.ScoringModel
    @Binding var start: Date
    @Binding var end: Date
    @Binding var repeats: Bool
    @Binding var isPublic: Bool

    // MARK: - Private Properties

    @State private var underlyingScoringModel: UnderlyingScoringModel?
    @State private var underlyingWorkoutType: WorkoutType?
    @State private var underlyingWorkoutMetrics: [WorkoutMetric] = []
    @State private var showScoringModelsLearnMore = false

    private var newScoringModel: Competition.ScoringModel? {
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
            if let underlyingWorkoutType, !underlyingWorkoutMetrics.isEmpty {
                return .workout(underlyingWorkoutType, underlyingWorkoutMetrics)
            }
            return nil
        case .none:
            return nil
        }
    }

    private var detailsFooterTexts: [String] {
        .build {
            if repeats { L10n.Competition.Edit.Repeats.disclaimer }
            if isPublic { L10n.Competition.Edit.Public.disclaimer }
        }
    }

    // MARK: - Lifecycle

    init(name: Binding<String>, scoringModel: Binding<Competition.ScoringModel>, start: Binding<Date>, end: Binding<Date>, repeats: Binding<Bool>, isPublic: Binding<Bool>) {
        _name = name
        _scoringModel = scoringModel
        _start = start
        _end = end
        _repeats = repeats
        _isPublic = isPublic

        switch scoringModel.wrappedValue {
        case .activityRingCloseCount:
            _underlyingScoringModel = .init(initialValue: .activityRingCloseCount)
        case .percentOfGoals:
            _underlyingScoringModel = .init(initialValue: .percentOfGoals)
        case .rawNumbers:
            _underlyingScoringModel = .init(initialValue: .rawNumbers)
        case .stepCount:
            _underlyingScoringModel = .init(initialValue: .stepCount)
        case .workout(let type, let metrics):
            _underlyingScoringModel = .init(initialValue: .workout)
            _underlyingWorkoutType = .init(initialValue: type)
            _underlyingWorkoutMetrics = .init(initialValue: metrics)
        }
    }

    // MARK: - View

    var body: some View {
        Group {
            Section {
                TextField(L10n.Competition.Edit.name, text: $name)

                DatePicker(
                    L10n.Competition.Edit.starts,
                    selection: $start,
                    in: PartialRangeFrom(min(start, Date())),
                    displayedComponents: [.date]
                )
                DatePicker(
                    L10n.Competition.Edit.ends,
                    selection: $end,
                    in: PartialRangeFrom(start.addingTimeInterval(1.days)),
                    displayedComponents: [.date]
                )

                Toggle(L10n.Competition.Edit.repeats, isOn: $repeats)
                Toggle(L10n.Competition.Edit.public, isOn: $isPublic)
            } header: {
                Text(L10n.Competition.Edit.title)
            } footer: {
                if detailsFooterTexts.isNotEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(detailsFooterTexts, id: \.self, content: Text.init)
                    }
                }
            }

            scoringModelSection
        }
    }

    private var scoringModelSection: some View {
        Section {

            EnumPicker(L10n.Competition.Edit.scoringModel, selection: $underlyingScoringModel)

            if underlyingScoringModel == .workout {
                EnumPicker(L10n.Competition.Edit.workoutType, selection: $underlyingWorkoutType, allowsNoSelection: true)

                if let underlyingWorkoutType {
                    MultiPicker(
                        title: L10n.Competition.Edit.workoutMetrics,
                        selection: $underlyingWorkoutMetrics,
                        options: underlyingWorkoutType.metrics
                    )
                }
            }
        } header: {
            Text(L10n.Competition.Edit.scoringModel)
        } footer: {
            Button(L10n.Competition.Edit.learnMore, toggling: $showScoringModelsLearnMore)
        }
        .onChange(of: newScoringModel) { newScoringModel in
            guard let newScoringModel else { return }
            scoringModel = newScoringModel
        }
        .sheet(isPresented: $showScoringModelsLearnMore) {
            List {
                ForEach(UnderlyingScoringModel.allCases, id: \.description) { scoringModel in
                    VStack(alignment: .leading) {
                        Text(scoringModel.description)
                        Text(scoringModel.details)
                            .foregroundColor(.secondaryLabel)
                    }
                }
            }
            .navigationTitle(L10n.Competition.Edit.scoringModel)
            .embeddedInNavigationView()
        }
    }
}

#if DEBUG
struct EditCompetitionView_Previews: PreviewProvider {

    private struct Preview: View {

        @State private var competition: Competition = .mock

        var body: some View {
            Form {
                EditCompetitionSection(
                    name: $competition.name,
                    scoringModel: $competition.scoringModel,
                    start: $competition.start,
                    end: $competition.end,
                    repeats: $competition.repeats,
                    isPublic: $competition.isPublic
                )
            }
        }
    }

    static var previews: some View {
        Preview()
            .navigationTitle("Competition Info")
            .embeddedInNavigationView()
    }
}
#endif
