import Combine
import CombineExt
import Resolver

final class NewCompetitionViewModel: ObservableObject {
    
    struct InviteFriendsRow: Identifiable {
        let id: String
        let name: String
        var invited: Bool
    }
    
    private enum Constants {
        static let defaultInterval: TimeInterval = 7
    }
    
    @Published var competition: Competition
    @Published var competitionInfoConfig = CompetitionInfo.Config(canEdit: true, editing: true)
    @Published var friendRows = [InviteFriendsRow]()
    
    var detailsFooterTexts: [String] {
        var detailsTexts = [String]()
        if competition.repeats {
            detailsTexts.append("This competition will restart the next day after it ends.")
        }
        if competition.isPublic {
            detailsTexts.append("Heads up! Anyone can join public competitions from the explore page.")
        }
        return detailsTexts
    }
    
    var createDisabled: Bool { disabledReason != nil }
    var disabledReason: String? {
        if competition.name.isEmpty {
            return "Please enter a name"
        } else if !competition.isPublic && competition.pendingParticipants.isEmpty {
            return "Please invite at least 1 friend"
        }
        return nil
    }
    
    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var userManager: AnyUserManager
        
    init() {
        competition = .init(
            name: "",
            owner: "",
            participants: [],
            pendingParticipants: [],
            scoringModel: .percentOfGoals,
            start: .now,
            end: .now.advanced(by: Constants.defaultInterval.days),
            repeats: false,
            isPublic: false,
            banner: nil
        )
        
        friendsManager.$friends
            .map { $0.map { InviteFriendsRow(id: $0.id, name: $0.name, invited: false) } }
            .assign(to: &$friendRows)
    }
    
    func create() {
        competition.owner = userManager.user.id
        competition.participants = [userManager.user.id]
        competitionsManager.create(competition)
    }
    
    func tapped(_ rowConfig: InviteFriendsRow) {
        if competition.pendingParticipants.contains(rowConfig.id) {
            competition.pendingParticipants.remove(rowConfig.id)
        } else {
            competition.pendingParticipants.append(rowConfig.id)
        }
        
        guard let index = friendRows.firstIndex(where: { $0.id == rowConfig.id }) else { return }
        friendRows[index].invited = competition.pendingParticipants.contains(rowConfig.id)
    }
}
