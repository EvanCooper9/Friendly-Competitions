import Combine
import CombineExt
import Resolver

final class NewCompetitionViewModel: ObservableObject {
    
    private enum Constants {
        static let defaultInterval = 7
    }
        
    @Published var name = ""
    @Published var start = Date.now.addingTimeInterval(1.days)
    @Published var end = Date.now.addingTimeInterval(Constants.defaultInterval.days + 1.days)
    @Published var repeats = false
    @Published var isPublic = false
    @Published var invitees = [String]()
    @Published var scoringModel = Competition.ScoringModel.percentOfGoals
    
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
    
    var createDisabled: Bool { disabledReason != nil }
    var disabledReason: String? {
        if name.isEmpty {
            return "Please enter a name"
        } else if !isPublic && invitees.isEmpty {
            return "Please invite at least 1 friend"
        }
        return nil
    }
    
    @Published var friends = [User]()
    
    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var userManager: AnyUserManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        friendsManager.$friends
            .assign(to: \.friends, on: self, ownership: .weak)
            .store(in: &cancellables)
    }
    
    func create() {
        let competition = Competition(
            name: name,
            owner: userManager.user.id,
            participants: [userManager.user.id],
            pendingParticipants: invitees,
            scoringModel: scoringModel,
            start: start,
            end: end,
            repeats: repeats,
            isPublic: isPublic,
            banner: nil
        )
        
        competitionsManager.create(competition)
    }
}
