import SwiftUI
import SwiftUIX

struct MultiPicker<Selection: CustomStringConvertible & Hashable & Identifiable>: View {

    let title: String
    @Binding var selection: [Selection]
    let options: [Selection]

    var body: some View {
        NavigationLink {
            List {
                ForEach(options) { option in
                    HStack {
                        Text(option.description)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .tag(option)
                            .onTapGesture { selection.toggle(option) }
                        if selection.contains(option) {
                            Image(systemName: .checkmark)
                                .font(.body.bold())
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .listStyle(.grouped)
        } label: {
            HStack {
                Text(title)
                Spacer()
                if selection.isNotEmpty {
                    Text(selection.map(\.description).joined(separator: ", "))
                        .lineLimit(1)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct CompetitionInfo: View {

    private enum UnderlyingScoringModel: String, CaseIterable {
        case percentOfGoals = "Percent of Goals"
        case rawNumbers = "Raw numbers"
        case workout = "Workout"
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
            if let underlyingWorkoutType = underlyingWorkoutType, !underlyingWorkoutMetrics.isEmpty {
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

                Picker("Scoring Model", selection: $underlyingScoringModel) {
                    Text("Select...").tag(UnderlyingScoringModel?.none)
                    ForEach(UnderlyingScoringModel.allCases, id: \.rawValue) { scoringModel in
                        Text(scoringModel.rawValue).tag(scoringModel as UnderlyingScoringModel?)
                    }
                }

                if underlyingScoringModel == .workout {
                    Picker("Workout type", selection: $underlyingWorkoutType) {
                        Text("Select...").tag(WorkoutType?.none)
                        ForEach(WorkoutType.allCases) { workoutType in
                            Text(workoutType.description).tag(workoutType as WorkoutType?)
                        }
                    }

                    if let underlyingWorkoutType = underlyingWorkoutType {
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
                    valueType: .other(systemImage: "plusminus.circle", description: "Scoring model")
                )
                if competition.repeats {
                    ImmutableListItemView(
                        value: "Yes",
                        valueType: .other(systemImage: "repeat.circle", description: "Restarts")
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
