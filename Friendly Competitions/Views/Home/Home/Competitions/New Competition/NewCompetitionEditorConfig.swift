import Foundation

struct NewCompetitionEditorConfig {

    private enum Constants {
        static let defaultInterval = 7
    }

    var name = ""

    var start = Date.now.addingTimeInterval(1.days)
    var end = Date.now.addingTimeInterval(Constants.defaultInterval.days + 1.days)
    var repeats = true
    var isPublic = false
    
    var detailsFooterTexts: [String] {
        var detailsTexts = [String]()
        if repeats {
            detailsTexts.append("This competition will restart the next day after it ends.")
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
}
