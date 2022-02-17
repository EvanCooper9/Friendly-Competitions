import Foundation

struct NewCompetitionEditorConfig {

    private enum Constants {
        static let defaultInterval = 7
    }

    var name = ""

    var start = Date.now.addingTimeInterval(1.days)
    var end = Date.now.addingTimeInterval(Constants.defaultInterval.days + 1.days)
    var repeats = false
    var isPublic = false

    var detailsFooterTexts: [String] {
        var detailsTexts = [String]()
        if repeats {
            let recurringInterval = Int(end.timeIntervalSince(start) / 1.days)
            detailsTexts.append("This competition will restart every \(recurringInterval) day(s).")
        }
        if isPublic {
            detailsTexts.append("Heads up! Anyone can join public competitions from the explore page.")
        }
        return detailsTexts
    }

    var invitees = [String]()
    var scoringModel = Competition.ScoringModel.percentOfGoals

    var createDisabled: Bool { disabledReason != nil }

    var disabledReason: String? {
        if name.isEmpty {
            return "Please enter a name"
        } else if !isPublic && invitees.isEmpty {
            return "Please invite at least 1 friend"
        }
        return nil
    }

    func competition(creator: User) -> Competition {
        .init(
            name: name,
            owner: creator.id,
            participants: [creator.id],
            pendingParticipants: invitees,
            scoringModel: scoringModel,
            start: start,
            end: end,
            repeats: repeats,
            isPublic: isPublic,
            banner: nil
        )
    }
}
