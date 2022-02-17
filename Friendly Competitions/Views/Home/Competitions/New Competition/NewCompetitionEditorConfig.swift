import Foundation

struct NewCompetitionEditorConfig {

    var name = ""
    var start = Date.now
    var end = Date.now.addingTimeInterval(7.days)
    var invitees = [String]()
    var scoringModel = Competition.ScoringModel.percentOfGoals

    var `public` = true
    var recurring = false

    var createDisabled: Bool { name.isEmpty || invitees.isEmpty }

    var disabledReason: String? {
        if name.isEmpty {
            return "Please enter a name"
        } else if invitees.isEmpty {
            return "Please invite at least 1 friend"
        }
        return nil
    }

    func competition(creator: User) -> Competition {
        .init(
            name: name,
            participants: [creator.id],
            pendingParticipants: invitees,
            scoringModel: scoringModel,
            start: start,
            end: end
        )
    }
}
