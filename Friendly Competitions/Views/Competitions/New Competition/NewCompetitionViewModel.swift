import Combine
import CombineExt
import Resolver

final class NewCompetitionViewModel: ObservableObject {
    
    private enum Constants {
        static let defaultInterval: TimeInterval = 7
    }
    
    @Published var competition: Competition
    @Published var invitees = [String]()
    
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
    
    @Published var friends = [User]()
    
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
        
        friendsManager.$friends.assign(to: &$friends)
    }
    
    func create() {
        competition.owner = userManager.user.id
        competition.participants = [userManager.user.id]
        competitionsManager.create(competition)
    }
}
