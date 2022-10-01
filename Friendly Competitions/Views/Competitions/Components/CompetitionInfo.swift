import ECKit
import SwiftUI
import SwiftUIX

struct CompetitionInfo: View {

    private enum UnderlyingScoringModel: String, CaseIterable, CustomStringConvertible, Identifiable {
        case percentOfGoals = "Percent of Goals"
        case rawNumbers = "Raw Numbers"
        case workout = "Workout"

        var id: RawValue { description }
        var description: String { rawValue }
    }
    
    @Binding var competition: Competition

    let editing: Bool
    let canSaveEdits: (Bool) -> Void

    @State private var underlyingScoringModel: UnderlyingScoringModel? = .workout
    @State private var underlyingWorkoutType: WorkoutType? = .running
    @State private var underlyingWorkoutMetrics: [WorkoutMetric] = [.distance]

    private var scoringModel: Competition.ScoringModel? {
        switch underlyingScoringModel {
        case .percentOfGoals:
            return .percentOfGoals
        case .rawNumbers:
            return .rawNumbers
        case .workout:
            if let underlyingWorkoutType, !underlyingWorkoutMetrics.isEmpty {
                return .workout(underlyingWorkoutType, Array(underlyingWorkoutMetrics))
            }
            return nil
        case .none:
            return nil
        }
    }

    private var canSave: Bool {
        !competition.name.isEmpty &&  scoringModel != nil && !competition.name.isEmpty
    }

    private var detailsFooterTexts: [String] {
        var detailsTexts = [String]()
        if competition.repeats {
            detailsTexts.append("This competition will restart the next day after it ends.")
        }
        if competition.isPublic {
            detailsTexts.append("Heads up! Anyone can join public competitions from the explore page.")
        }
        return detailsTexts
    }
    
    var body: some View {
        Section {
            if editing {
                TextField("Name", text: $competition.name)
                DatePicker(
                    "Starts",
                    selection: $competition.start,
                    in: PartialRangeFrom(min(competition.start, Date())),
                    displayedComponents: [.date]
                )
                DatePicker(
                    "Ends",
                    selection: $competition.end,
                    in: PartialRangeFrom(competition.start.addingTimeInterval(1.days)),
                    displayedComponents: [.date]
                )

                EnumPicker("ScoringModel", selection: $underlyingScoringModel, allowsNoSelection: true)

                if underlyingScoringModel == .workout {
                    EnumPicker("Workout type", selection: $underlyingWorkoutType, allowsNoSelection: true)

                    if let underlyingWorkoutType {
                        MultiPicker(
                            title: "Workout metrics",
                            selection: $underlyingWorkoutMetrics,
                            options: underlyingWorkoutType.metrics
                        )
                    }
                }

                Toggle("Repeats", isOn: $competition.repeats)
                Toggle("Public", isOn: $competition.isPublic)
            } else {
                ImmutableListItemView(
                    value: competition.start.formatted(date: .abbreviated, time: .omitted),
                    valueType: .date(description: competition.started ? "Started" : "Starts")
                )
                ImmutableListItemView(
                    value: competition.end.formatted(date: .abbreviated, time: .omitted),
                    valueType: .date(description: competition.ended ? "Ended" : "Ends")
                )
                ImmutableListItemView(
                    value: competition.scoringModel.displayName,
                    valueType: .other(systemImage: .plusminusCircle, description: "Scoring model")
                )
                if competition.repeats {
                    ImmutableListItemView(
                        value: "Yes",
                        valueType: .other(systemImage: .repeatCircle, description: "Restarts")
                    )
                }
            }
        } header: {
            Text("Details")
        } footer: {
            if editing, detailsFooterTexts.isNotEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(detailsFooterTexts, id: \.self, content: Text.init)
                }
            }
        }
        .onChange(of: canSave, perform: canSaveEdits)
        .onChange(of: scoringModel) { scoringModel in
            guard let scoringModel = scoringModel else { return }
            competition.scoringModel = scoringModel
        }
        .onChange(of: editing) { editing in
            guard !editing, let scoringModel = scoringModel else { return }
            competition.scoringModel = scoringModel
        }
    }
}

struct CompetitionInfo_Previews: PreviewProvider {

    private struct Preview: View {

        @State private var competition: Competition = .mock

        var body: some View {
            Form {
                CompetitionInfo(competition: $competition, editing: false) { _ in }
                CompetitionInfo(competition: $competition, editing: true) { _ in }
            }
        }
    }

    static var previews: some View {
        Preview()
            .navigationTitle("Competition Info")
            .embeddedInNavigationView()
    }
}
