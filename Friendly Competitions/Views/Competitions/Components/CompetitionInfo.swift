import SwiftUI

struct CompetitionInfo: View {
    
    struct Config {
        var canEdit: Bool
        var editing: Bool
        
        var onSave: (() -> Void)? = nil
                
        init(canEdit: Bool, editing: Bool = false) {
            self.canEdit = canEdit
            self.editing = editing
        }
        
        var editButtonTitle: String {
            editing ? "Cancel" : "Edit"
        }
    }
    
    @Binding var competition: Competition
    @Binding var config: Config
    
    var body: some View {
        Section("Details") {
            if config.editing {
                TextField("Name", text: $competition.name)
                DatePicker(
                    "Starts",
                    selection: $competition.start,
                    in: PartialRangeFrom(.now),
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
        }
    }
}

struct CompetitionInfo_Previews: PreviewProvider {
    
    private static var config = CompetitionInfo.Config(canEdit: true)
    
    static var previews: some View {
        Form {
            CompetitionInfo(competition: .constant(.mock), config: .constant(config))
        }
    }
}
