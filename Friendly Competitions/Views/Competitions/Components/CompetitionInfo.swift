import SwiftUI

struct CompetitionInfo: View {
    
    @Binding var competition: Competition
    let editing: Bool

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
                    in: PartialRangeFrom(DateFormatter.dateDashed.date(from: "2022-06-01")!),
                    displayedComponents: [.date]
                )
                DatePicker(
                    "Ends",
                    selection: $competition.end,
                    in: PartialRangeFrom(competition.start.addingTimeInterval(1.days)),
                    displayedComponents: [.date]
                )
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
                if let scoringModel = competition.scoringModel {
                    ImmutableListItemView(
                        value: scoringModel.displayName,
                        valueType: .other(systemImage: "plusminus.circle", description: "Scoring model")
                    )
                } else if let workoutType = competition.workoutType {
                    ImmutableListItemView(
                        value: workoutType.rawValue.localizedCapitalized,
                        valueType: .other(systemImage: "figure.walk.circle", description: "Workout")
                    )
                }
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
            if editing {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(detailsFooterTexts, id: \.self, content: Text.init)
                }
            }
        }
    }
}

struct CompetitionInfo_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            CompetitionInfo(competition: .constant(.mock), editing: false)
            CompetitionInfo(competition: .constant(.mock), editing: true)
        }
    }
}
